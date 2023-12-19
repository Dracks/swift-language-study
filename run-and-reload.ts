import fs  from "fs";
import { spawn} from 'node:child_process';
import YAML from 'yaml'

let oldChild : ReturnType<typeof spawn>

interface Config {
    watch: string[]
    spawn: [string, string[]]
}

const file = fs.readFileSync('./.run-and-reload.yaml', 'utf8')
const config :Config = YAML.parse(file)
console.log(config)

const stopAndStart = ()=>{
    if (oldChild){
        oldChild.kill("SIGINT")
    }

    const child = spawn(config.spawn[0], config.spawn[1])

    child.stdout.on('data', (data) => {
        console.log(`stdout: ${data}`);
    });

    child.stderr.on('data', (data) => {
        console.error(`stderr: ${data}`);
    });

    child.on('close', (code) => {
        console.log(`child process exited with code ${code}`);
    }); 

    oldChild = child

}
for  (const folder of config.watch) {
    fs.watch(folder, {recursive: true}, function (event, filename) {
        console.log('event is: ' + event);
        if (filename && filename.endsWith('.swift')) {
            console.log('filename provided: ' + filename);
            stopAndStart()
        } else {
            console.log('filename not provided');
        }
    });
    
}
stopAndStart()
