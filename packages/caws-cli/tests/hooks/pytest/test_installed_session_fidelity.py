"""Final-consumer artifacts from installed session-log dispatch, not parser counts."""
import hashlib
import json
from pathlib import Path
import subprocess
import sqlite3
import unittest

from test_machine_hook_selection import MachineHookSelection as Installation, PACKAGE


def codex(kind, **payload):
    return {'type': 'response_item', 'timestamp': '2026-09-12T12:00:01Z',
            'payload': {'type': kind, **payload}}


class InstalledSessionFidelity(unittest.TestCase):
    setUp = Installation.setUp
    configure = Installation.configure

    def prepare(self, rows, surface='codex'):
        self.surface = surface
        settings = self.home / 'surfaces' / surface / 'settings.json'
        settings.parent.mkdir(parents=True, exist_ok=True)
        settings.write_text('{"version":1,"enabled":true}')
        self.config['extensions'] = {}
        if 'session-log.sh' in self.config['disabled']['stop']:
            self.config['disabled']['stop'].remove('session-log.sh')
        self.configure()
        self.transcript = self.root / (surface + '.jsonl')
        self.transcript.write_text(''.join(json.dumps(row) + '\n' for row in rows))
        self.logs = self.repo / '.caws/sessions' / surface
        self.logs.mkdir(parents=True, exist_ok=True)

    def render(self, label):
        argv = ['python3', str(self.home / 'bin/caws-hook'), self.surface, 'stop', '--system']
        payload = {'session_id': self.surface, 'cwd': str(self.repo),
                   'transcript_path': str(self.transcript), 'hook_event_name': 'Stop'}
        result = subprocess.run(argv, cwd=self.repo, env=self.env, capture_output=True,
                                input=json.dumps(payload).encode(), timeout=40)
        for name, data in [('stdout', result.stdout), ('stderr', result.stderr)]:
            (self.root / (label + '.' + name)).write_bytes(data)
        receipt = {'argv': argv, 'exit_code': result.returncode, 'payload': payload,
                   'runtime_digest': self.runtime.name, 'artifacts': str(self.logs)}
        (self.root / (label + '.command.json')).write_text(json.dumps(receipt, indent=2))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(b'Traceback', result.stderr)
        return [json.loads(path.read_text()) for path in sorted(self.logs.glob('turn-*.json'))]

    def validate(self, payload):
        path = self.root / 'schema-input.json'
        path.write_text(json.dumps(payload))
        script = """
const fs=require('fs'); const Ajv=require('ajv/dist/2020').default;
const schema=JSON.parse(fs.readFileSync(process.argv[1]));
// Contract containers must DECLARE every emitted field, even if a compatible
// schema permits extensions. Arbitrary captured tool payloads remain open.
for (const key of ['turnArtifact','turnContext','timelineItem','hookContext','commandRef','searchRef','artifactRef'])
  schema.$defs[key].additionalProperties=false;
const validate=new Ajv({strict:false,allErrors:true}).compile(schema);
const valid=validate(JSON.parse(fs.readFileSync(process.argv[2])));
console.log(JSON.stringify({valid,errors:validate.errors},null,2)); process.exit(valid?0:1);
"""
        result = subprocess.run(['node', '-e', script, str(self.runtime / 'lib/session-log.schema.json'),
                                 str(path)], cwd=PACKAGE, capture_output=True)
        (self.root / 'schema-validation.json').write_bytes(result.stdout)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_codex_native_seam_preserves_raw_evidence_and_filters_injected_messages(self):
        program = ('const prose = \'tools.exec_command({cmd:"fabricated"})\';\n'
                   '// tools.exec_command({cmd:"also fabricated"})\n'
                   'if (false) { await tools.exec_command({cmd:"conditional command"}); }\n'
                   'await tools.exec_command({cmd:"printf observation"});\n')
        output = 'Process exited with code 7\n' + 'exact-output-' * 1000
        rows = [
            {'type':'session_meta','payload':{'id':'codex','forked_from':'parent-session'}},
            {'type':'turn_context','payload':{'turn_id':'turn-one'}},
            codex('message',role='user', content=[{'type':'input_text','text':'injected instructions'},
                                                 {'type':'input_text','text':'Inspect the outcome.'}],
                  internal_chat_message_metadata_passthrough={'content_item_kinds':['context.instructions','user.text']}),
            codex('message',role='assistant',channel='analysis',content=[{'type':'output_text','text':'internal marker excluded'}]),
            codex('custom_tool_call',name='functions.exec',call_id='call-one',input=program),
            codex('custom_tool_call_output',call_id='call-one',output=output),
            codex('message',role='assistant',content=[{'type':'output_text','text':'The command returned an error.'}]),
        ]
        self.prepare(rows)
        turns = self.render('codex-fidelity')
        self.assertEqual(len(turns), 1)
        turn = turns[0]
        self.assertEqual(turn['user'], 'Inspect the outcome.')
        self.assertEqual(turn['context']['branch'], 'main')
        self.assertNotIn('internal marker excluded', json.dumps(turn))
        self.assertEqual(turn['context']['lineage']['parent_session_id'], 'parent-session')
        self.assertEqual(turn['context']['lineage']['authority'], 'none')
        call = next(item for item in turn['timeline'] if item['kind'] == 'tool_call')
        self.assertEqual(call['source_harness'], 'codex')
        self.assertEqual(call['input_raw'], program)
        self.assertEqual(call['output'], output)
        self.assertTrue(call['is_error'])
        self.assertFalse(call['output_truncated'])
        self.assertEqual([a['command'] for a in call['inner_actions']],
                         ['conditional command', 'printf observation'])
        self.assertTrue(all(a['execution'] == 'not_observed' for a in call['inner_actions']))
        self.validate(turn)

    def test_sidecar_only_change_is_visible_without_claiming_delivery(self):
        self.prepare([codex('message',role='user',content=[{'type':'input_text','text':'Blocked operation.'}])])
        self.render('sidecar-before')
        sidecar = self.logs / 'hook-events.jsonl'
        record = {'session_id':'codex','timestamp':'2026-09-12T12:00:02Z','handler':'guard-fixture',
                  'status':'completed','exit_code':2,'adapter_exit_code':2,'stdout':'{"decision":"block","reason":"foreign tenure"}',
                  'stderr':'','observation_boundary':'handler_return','delivery':'not_observed',
                  'invocation_id':'fixture-invocation','runtime_digest':self.runtime.name,'source_sha256':'a'*64}
        with sidecar.open('a') as target:
            target.write(json.dumps(record)+'\n')
            target.write(json.dumps({**record,'session_id':'other-session','handler':'foreign-noise'})+'\n')
        turn = self.render('sidecar-after')[0]
        contexts = [entry for entry in turn['hook_contexts'] if entry['hook_name']=='guard-fixture']
        self.assertEqual(len(contexts), 1)
        self.assertEqual((contexts[0]['observation_boundary'],contexts[0]['delivery']),
                         ('handler_return','not_observed'))
        self.assertEqual(contexts[0]['source_sha256'], 'a'*64)
        self.assertEqual(turn['status'], 'blocked')
        self.assertNotIn('foreign-noise',json.dumps(turn))
        self.validate(turn)

    def test_missing_transcript_preserves_turns_and_corrupted_output_is_rebuilt(self):
        self.prepare([codex('message',role='user',content=[{'type':'input_text','text':'Retain this request.'}])])
        self.render('retained-before')
        target = self.logs / 'turn-001.json'
        before = target.read_bytes()
        original = self.transcript.read_bytes()
        self.transcript.unlink()
        self.render('missing-transcript')
        self.assertEqual(target.read_bytes(),before)
        state = json.loads((self.logs / '.render-state.json').read_text())
        self.assertEqual(state['status'], 'retained_missing_transcript')
        self.assertEqual(state['inputs_before']['transcript_path']['status'], 'missing')
        self.transcript.write_bytes(original)
        target.write_bytes(b'corrupted JSON')
        repaired = self.render('corruption-repaired')
        self.assertEqual(repaired[0]['user'],'Retain this request.')
        self.validate(repaired[0])

    def test_dsh_kimi_claude_qwen_and_zcode_native_rows_reach_installed_renderers(self):
        cases = {
            'dsh': [{'type':'user/message','time':1700000000000,'data':{'source':{'kind':'user'},'content':[{'type':'text','text':'DSH user'}]}},
                    {'type':'tool/call','time':1700000000100,'data':{'name':'Read','callId':'dsh-call','arguments':{'file_path':'dsh.txt'}}}],
            'kimi-code': [{'type':'turn.prompt','time':1700000000000,'input':[{'type':'text','text':'Kimi user'}]},
                          {'type':'context.append_loop_event','time':1700000000100,'event':{'type':'tool.call','name':'Read','toolCallId':'kimi-call','args':{'path':'kimi.txt'}}}],
            'claude-code': [{'type':'user','message':{'content':'Claude user'}},
                            {'type':'assistant','message':{'content':[{'type':'tool_use','name':'Read','id':'claude-call','input':{'file_path':'claude.txt'}}]}}],
            'opencode': [{'type':'user','message':{'content':'OpenCode reconstructed user'}},
                         {'type':'assistant','message':{'content':[{'type':'tool_use','name':'Read','id':'opencode-call','input':{'file_path':'opencode.txt'}}]}}],
            'qwen-code': [{'type':'user','message':{'parts':[{'text':'Qwen user'}]}},
                          {'type':'assistant','message':{'parts':[{'functionCall':{'name':'read_file','id':'qwen-call','args':{'file_path':'qwen.txt'}}}]}}],
            'zcode': [{'type':'model_io','turnId':'zcode-turn','response':{'text':'ZCode response','toolCalls':[{'name':'Read','id':'zcode-call','input':{'file_path':'zcode.txt'}}]}}],
        }
        for surface, rows in cases.items():
            with self.subTest(surface=surface):
                self.prepare(rows,surface)
                turns = self.render('surface-'+surface)
                self.assertEqual(len(turns),1)
                self.assertEqual(turns[0]['refs']['files']['read'],[surface.split('-')[0]+'.txt'])
                self.validate(turns[0])

    def test_durable_database_snapshot_selects_one_session_and_empty_is_not_stale_hit(self):
        for surface in ('opencode','zcode'):
            with self.subTest(surface=surface):
                self.prepare([],surface)
                database = self.root / (surface + '.sqlite')
                connection = sqlite3.connect(database)
                connection.executescript('CREATE TABLE message(id TEXT,session_id TEXT,data TEXT,time_created INTEGER);'
                                         'CREATE TABLE part(id TEXT,message_id TEXT,data TEXT,time_created INTEGER);')
                for session in (surface,'foreign-session'):
                    connection.execute('INSERT INTO message VALUES(?,?,?,?)',
                                       (session,session,json.dumps({'role':'user'}),1000))
                    for index in (1,2):
                        connection.execute('INSERT INTO part VALUES(?,?,?,?)',
                            (session+str(index),session,json.dumps({'type':'text','text':session+' part '+str(index)}),1000+index))
                connection.commit()
                before = hashlib.sha256(database.read_bytes()).hexdigest()
                self.env['CAWS_TRANSCRIPT_DATABASE'] = str(database)
                turn = self.render('database-'+surface)[0]
                self.assertEqual(turn['user'],surface+' part 1\n\n'+surface+' part 2')
                self.assertNotIn('foreign-session',json.dumps(turn))
                self.assertEqual(hashlib.sha256(database.read_bytes()).hexdigest(),before)
                receipt = json.loads((self.logs / '.transcript-projection.receipt.json').read_text())
                self.assertEqual(receipt['source_mode'],'sqlite_read_transaction')
                self.assertEqual([row['message_id'] for row in receipt['source_rows']],[surface,surface])
                self.assertEqual(receipt['status'],'projected')
                connection.execute('DELETE FROM message WHERE session_id=?',(surface,))
                connection.commit()
                connection.close()
                self.render('database-empty-'+surface)
                receipt = json.loads((self.logs / '.transcript-projection.receipt.json').read_text())
                self.assertEqual(receipt['status'],'empty')
                self.assertEqual((self.logs / '.transcript-projection.jsonl').read_bytes(),b'')
                state = json.loads((self.logs / '.render-state.json').read_text())
                self.assertFalse(state['outputs_current'])
                self.assertEqual(state['status'],'retained_empty_source')


if __name__ == '__main__':
    unittest.main()
