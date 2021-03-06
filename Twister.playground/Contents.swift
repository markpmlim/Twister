// A playground can be used to test geometry shader modifiers quickly.
// To demonstrate a twisting effect using a geometry shader modifier
// https://www.objc.io/issues/18-games/scenekit/#extending-the-default-rendering
// An explicit animation of the rendered object is now working correctly.
// Both SCNGeometry and SCNMaterial conforms to the SCNAnimatable protocol.
// Requires: XCode 8.3.2 macOS Sierra or later

import Cocoa
import SceneKit
import PlaygroundSupport

// Set up the geometry of the node to be rendered.
let torus = SCNTorus(ringRadius: 1.5, pipeRadius: 0.5)
let blueColor = NSColor(calibratedRed: 0.0,
                        green: 0.5,
                        blue: 0.9,
                        alpha: 1.0)
torus.firstMaterial?.diffuse.contents = blueColor
torus.firstMaterial?.specular.contents = NSColor.white
// Instantiate the node.
let torusNode = SCNNode(geometry: torus)

// Create a simple scene.
let scene = SCNScene()
scene.rootNode.addChildNode(torusNode)

let frameRect = NSRect(x: 0, y: 0,
                       width: 480, height: 320)
let sceneView = SCNView(frame: frameRect)

sceneView.scene = scene
sceneView.backgroundColor = NSColor.gray
sceneView.autoenablesDefaultLighting = true
sceneView.allowsCameraControl = true
sceneView.showsStatistics = true

// Geometry - Metal will translate the OpenGL code.
let geometryShaderModifier =
    "uniform float twistFactor;\n" +
    "mat4 rotationAroundX(float angle) {\n" +
    "return mat4(1.0,    0.0,         0.0,        0.0,\n" +
    "            0.0,    cos(angle), -sin(angle), 0.0,\n" +
    "            0.0,    sin(angle),  cos(angle), 0.0,\n" +
    "            0.0,    0.0,         0.0,        1.0);\n" +
    "}\n" +
    "#pragma body\n" +
    "float rotationAngle = _geometry.position.x * twistFactor;\n" +
    "mat4 rotationMatrix = rotationAroundX(rotationAngle);\n" +
    "_geometry.position *= rotationMatrix;\n" +
    "vec4 twistedNormal = vec4(_geometry.normal, 1.0) * rotationMatrix;\n" +
    "_geometry.normal   = twistedNormal.xyz;\n"

// Attach the shader modifier to the torus' geometry
torus.shaderModifiers = [.geometry : geometryShaderModifier]

// The uniform "twistFactor" must be assigned a value.
torus.setValue(5.0, forKey: "twistFactor")

// CABasicAnimation is a sub-class of CAAnimation which conforms to SCNAnimationProtocol
// Check: Is the keyPath "twistFactor" KVC?
// Yes, SceneKit binds values of shader variables using KVO.
// Custom uniforms can be animated using explicit animations.
// There is no animation if the key path in the statement below is "twistFactor".
// Ref. Animating SceneKit Content - Explicitly Create an Animation
let twistAnimation = CABasicAnimation(keyPath: "geometry.twistFactor")
twistAnimation.fromValue = NSNumber(value: 5.0)
twistAnimation.toValue   = NSNumber(value: 0.0)
twistAnimation.duration  = 2.0
twistAnimation.autoreverses  = true
twistAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
twistAnimation.repeatCount = .greatestFiniteMagnitude

// No animation if the animation is attached to "torus" (an instance of SCNGeometry)
// even though the class SCNGeometry conforms to SCNAnimationProtocol
torusNode.addAnimation(twistAnimation, forKey: "Twist the torus")

PlaygroundPage.current.liveView = sceneView
