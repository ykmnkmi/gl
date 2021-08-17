import 'dart:html' show CanvasElement, document, window;
import 'dart:math' show Random, Rectangle;
import 'dart:typed_data' show Float32List;
import 'dart:web_gl';

void main() {
  final canvas = document.querySelector('canvas') as CanvasElement;
  final context = canvas.getContext('webgl') as RenderingContext;

  final vertexShader = createShader(context, WebGL.VERTEX_SHADER, vertexShaderSource);
  final fragmentShader = createShader(context, WebGL.FRAGMENT_SHADER, fragmentShaderSource);

  final program = createProgram(context, vertexShader, fragmentShader);

  final aPositionLocation = context.getAttribLocation(program, 'a_position');
  final uResolutionLocation = context.getUniformLocation(program, 'u_resolution');
  final uColorLocation = context.getUniformLocation(program, 'u_color');

  final positionBuffer = context.createBuffer();
  context.bindBuffer(WebGL.ARRAY_BUFFER, positionBuffer);

  final random = Random();
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

    for (var i = 0; i < 50; ++i) {
      final left = random.nextInt(300);
      final width = random.nextInt(300);
      final top = random.nextInt(300);
      final height = random.nextInt(300);
      final rectangle = Rectangle<num>(left, width, top, height);
      setRectangle(context, rectangle);

      final x = random.nextDouble();
      final y = random.nextDouble();
      final z = random.nextDouble();
      final w = 1.0;
      context
        ..uniform4f(uColorLocation, x, y, z, w)
        ..drawArrays(WebGL.TRIANGLES, 0, 6);
    }
  }

  render();

  window.onResize.listen((event) {
    render();
  });
}

void setRectangle(RenderingContext context, Rectangle<num> rectangle) {
  final x1 = rectangle.left;
  final x2 = x1 + rectangle.width;
  final y1 = rectangle.top;
  final y2 = y1 + rectangle.height;

  final positions = <num>[x1, y1, x2, y1, x1, y2, x1, y2, x2, y1, x2, y2];
  context.bufferData(WebGL.ARRAY_BUFFER, Float32List.fromList(positions.cast<double>()), WebGL.STATIC_DRAW);
}

Shader createShader(RenderingContext context, int type, String source) {
  final shader = context.createShader(type);
  context
    ..shaderSource(shader, source)
    ..compileShader(shader);

  final succes = context.getShaderParameter(shader, WebGL.COMPILE_STATUS) as bool;
  if (succes) {
    return shader;
  }

  final infoLog = context.getShaderInfoLog(shader);
  context.deleteShader(shader);
  throw Exception(infoLog);
}

Program createProgram(RenderingContext context, Shader vertex, Shader fragment) {
  final program = context.createProgram();
  context
    ..attachShader(program, vertex)
    ..attachShader(program, fragment)
    ..linkProgram(program);

  final success = context.getProgramParameter(program, WebGL.LINK_STATUS) as bool;
  if (success) {
    return program;
  }

  final infoLog = context.getProgramInfoLog(program);
  context.deleteProgram(program);
  throw Exception(infoLog);
}

const String vertexShaderSource = '''
attribute vec2 a_position;

uniform vec2 u_resolution;

// все шейдеры имеют функцию main
void main() {
  // преобразуем положение в пикселях к диапазону от 0.0 до 1.0
  vec2 zeroToOne = a_position / u_resolution;

  // преобразуем из 0->1 в 0->2
  vec2 zeroToTwo = zeroToOne * 2.0;

  // преобразуем из 0->2 в -1->+1 (пространство отсечения)
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
