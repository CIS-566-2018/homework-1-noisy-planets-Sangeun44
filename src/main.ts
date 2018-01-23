import {vec3, vec4} from 'gl-matrix';
import * as Stats from 'stats-js';
import * as DAT from 'dat-gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';

import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  shaders: 'lambert',
  shape: 'cube',
  color: [80, 40, 1, 0.9], // CSS string
  tesselations: 5,
  'Load Scene': loadScene // A function pointer, essentially
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let count: number = 0.0;

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function main() {
  // Initial display for framerate
  const stats = Stats();
  stats.setMode(0);
  stats.domElement.style.position = 'absolute';
  stats.domElement.style.left = '0px';
  stats.domElement.style.top = '0px';
  document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.addColor(controls, 'color');
  gui.add(controls, 'shaders', ['lambert', 'vertex']);
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'shape', ['cube', 'square', 'icosphere']);

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const vertex = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/vertex-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/vertex-frag.glsl')),
  ]);

  const lambert = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  // This function will be called every frame
  function tick() {
    let new_color = vec4.fromValues(controls.color[0]/256, controls.color[1]/256, controls.color[2]/256, 1);
    
    if(controls.shaders === 'lambert') {
      lambert.setGeometryColor(new_color);  
      
      camera.update();
      stats.begin();
  
      gl.viewport(0, 0, window.innerWidth, window.innerHeight);
  
      renderer.clear();
      if(controls.shape === 'cube') {
        renderer.render(camera, lambert, [cube]);
      }
      else if(controls.shape === 'square') {
        renderer.render(camera, lambert, [square]);
      }
      else if(controls.shape === 'icosphere') {
        renderer.render(camera, lambert, [icosphere]);
      }
    }

    else if (controls.shaders === 'vertex') {
      vertex.setGeometryColor(new_color);  
      count += 1;
      vertex.setTime(count);
      camera.update();  
      stats.begin();
  
      gl.viewport(0, 0, window.innerWidth, window.innerHeight);
  
      renderer.clear();
      if(controls.shape === 'cube') {
        renderer.render(camera, vertex, [cube]);
      }
      else if(controls.shape === 'square') {
        renderer.render(camera, vertex, [square]);
      }
      else if(controls.shape === 'icosphere') {
        renderer.render(camera, vertex, [icosphere]);
      }
    }


    stats.end();

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick();
}

main();