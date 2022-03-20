import 'dart:html' show CanvasElement, document, window;
import 'dart:math' show Random, Rectangle;
import 'dart:typed_data' show Float32List;
import 'dart:web_gl';

import 'cast.dart';

void main() {
  var canvas = document.querySelector('canvas').as<CanvasElement>();
  var context = canvas.getContext('webgl').as<RenderingContext>();

  var vertexShader = createShader(context, WebGL.VERTEX_SHADER, vertexShaderSource);
  var fragmentShader = createShader(context, WebGL.FRAGMENT_SHADER, fragmentShaderSource);

  var program = createProgram(context, vertexShader, fragmentShader);

  var aPositionLocation = context.getAttribLocation(program, 'a_position');
  var uResolutionLocation = context.getUniformLocation(program, 'u_resolution');
  var uColorLocation = context.getUniformLocation(program, 'u_color');

  var positionBuffer = context.createBuffer();
  context.bindBuffer(WebGL.ARRAY_BUFFER, positionBuffer);

  var random = Random();
  var width = canvas.clientWidth;
  var height = canvas.clientHeight;

  void render() {
    width = canvas.clientWidth;
    height = canvas.clientHeight;
    canvas.width = width;
    canvas.height = height;
    context
      ..viewport(0, 0, width, height)
      ..clearColor(0.0, 0.0, 0.0, 0.0)
      ..clear(WebGL.COLOR_BUFFER_BIT)
      ..useProgram(program)
      ..enableVertexAttribArray(aPositionLocation)
      ..bindBuffer(WebGL.ARRAY_BUFFER, positionBuffer)
      ..vertexAttribPointer(aPositionLocation, 2, WebGL.FLOAT, false, 0, 0)
      ..uniform2f(uResolutionLocation, width, height);

    for (var i = 0; i < 10; ++i) {
      var left = random.nextInt(300).as<double>();
      var width = random.nextInt(300).as<double>();
      var top = random.nextInt(300).as<double>();
      var height = random.nextInt(300).as<double>();
      var rectangle = Rectangle<double>(left, width, top, height);
      setRectangle(context, rectangle);

      var x = random.nextDouble();
      var y = random.nextDouble();
      var z = random.nextDouble();
      var w = 1.0;
      context
        ..uniform4f(uColorLocation, x, y, z, w)
        ..drawArrays(WebGL.TRIANGLES, 0, 6);
    }
  }

  render();
}

void setRectangle(RenderingContext context, Rectangle<double> rectangle) {
  var x1 = rectangle.left;
  var x2 = x1 + rectangle.width;
  var y1 = rectangle.top;
  var y2 = y1 + rectangle.height;

  var positions = <double>[x1, y1, x2, y1, x1, y2, x1, y2, x2, y1, x2, y2];
  context.bufferData(WebGL.ARRAY_BUFFER, Float32List.fromList(positions), WebGL.STATIC_DRAW);
}

Shader createShader(RenderingContext context, int type, String source) {
  var shader = context.createShader(type);
  context
    ..shaderSource(shader, source)
    ..compileShader(shader);

  var succes = context.getShaderParameter(shader, WebGL.COMPILE_STATUS).as<bool>();
  if (succes) {
    return shader;
  }

  var infoLog = context.getShaderInfoLog(shader);
  context.deleteShader(shader);
  throw Exception(infoLog);
}

Program createProgram(RenderingContext context, Shader vertex, Shader fragment) {
  var program = context.createProgram();
  context
    ..attachShader(program, vertex)
    ..attachShader(program, fragment)
    ..linkProgram(program);

  var success = context.getProgramParameter(program, WebGL.LINK_STATUS).as<bool>();
  if (success) {
    return program;
  }

  var infoLog = context.getProgramInfoLog(program);
  context.deleteProgram(program);
  throw Exception(infoLog);
}

const String vertexShaderSource = '''
attribute vec2 a_position;
uniform vec2 u_resolution;

void main() {
  vec2 zeroToOne = a_position / u_resolution;
  vec2 zeroToTwo = zeroToOne * 2.0;
  vec2 clipSpace = zeroToTwo - 1.0;
  gl_Position = vec4(clipSpace * vec2(1, -1), 0, 1);
}
''';

const String fragmentShaderSource = '''
precision mediump float;
uniform vec4 u_color;

void main() {
  gl_FragColor = u_color;
}
''';
