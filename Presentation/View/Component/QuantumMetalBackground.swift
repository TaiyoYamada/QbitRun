import SwiftUI
import MetalKit

// A robust Metal-based animated background for the Quantum Mode Card.
struct QuantumMetalBackground: UIViewRepresentable {
    var colors: [Color]
    @Binding var phase: Double
    @Binding var speed: Double

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.backgroundColor = .clear
        mtkView.isOpaque = false // crucial for glassmorphism layering
        mtkView.delegate = context.coordinator
        
        // Optimize for battery and performance
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false
        mtkView.framebufferOnly = true

        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // Extract up to 3 colors
        let c1 = colors.indices.contains(0) ? colors[0] : .clear
        let c2 = colors.indices.contains(1) ? colors[1] : c1
        let c3 = colors.indices.contains(2) ? colors[2] : c2

        context.coordinator.color1 = c1.toVector()
        context.coordinator.color2 = c2.toVector()
        context.coordinator.color3 = c3.toVector()
        
        context.coordinator.basePhase = Float(phase)
        context.coordinator.speed = Float(speed)
    }

    func makeCoordinator() -> Renderer {
        Renderer(device: MTLCreateSystemDefaultDevice())
    }

    class Renderer: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        
        var time: Float = 0.0
        var basePhase: Float = 0.0
        var speed: Float = 1.0
        
        var color1: SIMD4<Float> = SIMD4<Float>(0.0, 0.5, 1.0, 1.0)
        var color2: SIMD4<Float> = SIMD4<Float>(0.0, 1.0, 0.5, 1.0)
        var color3: SIMD4<Float> = SIMD4<Float>(0.5, 0.0, 1.0, 1.0)

        // Using a single quad
        let vertexData: [Float] = [
            -1.0, -1.0, 0.0, 0.0,
             1.0, -1.0, 1.0, 0.0,
            -1.0,  1.0, 0.0, 1.0,
             1.0,  1.0, 1.0, 1.0,
        ]
        var vertexBuffer: MTLBuffer?

        init(device: MTLDevice?) {
            self.device = device
            super.init()
            
            guard let device = device else { return }
            self.commandQueue = device.makeCommandQueue()
            self.vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
            
            setupPipeline(device: device)
        }

        private func setupPipeline(device: MTLDevice) {
            let shaderSource = """
            #include <metal_stdlib>
            using namespace metal;

            struct VertexIn {
                float2 position;
                float2 uv;
            };

            struct VertexOut {
                float4 position [[position]];
                float2 uv;
            };

            struct Uniforms {
                float time;
                float padding;
                float2 resolution;
                float4 color1;
                float4 color2;
                float4 color3;
            };

            vertex VertexOut vertex_main(const device VertexIn* vertex_array [[buffer(0)]],
                                         unsigned int vid [[vertex_id]]) {
                VertexOut out;
                out.position = float4(vertex_array[vid].position, 0.0, 1.0);
                out.uv = vertex_array[vid].uv;
                return out;
            }

            // Pseudo-random noise
            float random(float2 st) {
                return fract(sin(dot(st.xy, float2(12.9898,78.233))) * 43758.5453123);
            }

            // Interpolated noise
            float noise(float2 st) {
                float2 i = floor(st);
                float2 f = fract(st);

                float a = random(i);
                float b = random(i + float2(1.0, 0.0));
                float c = random(i + float2(0.0, 1.0));
                float d = random(i + float2(1.0, 1.0));

                float2 u = f * f * (3.0 - 2.0 * f);
                return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
            }

            // Fractal Brownian Motion (for slow, thick liquid-like distortion)
            float fbm(float2 st) {
                float value = 0.0;
                float amplitude = 0.5;
                for (int i = 0; i < 3; i++) {
                    value += amplitude * noise(st);
                    st *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }

            fragment float4 fragment_main(VertexOut in [[stage_in]],
                                          constant Uniforms& uniforms [[buffer(1)]]) {
                float2 uv = in.uv;
                float t = uniforms.time * 0.25; // Slow down time for a heavy, liquid feel
                
                // 1. Calculate base slow wave distortion (liquid refraction)
                // We distort the X coordinate using sine waves moving across Y, and vice versa.
                float wave1 = sin(uv.x * 4.0 + t) * 0.15;
                float wave2 = cos(uv.x * 2.5 - t * 0.7) * 0.1;
                
                // Apply Fractal Brownian Motion for heavier, organic liquid distortion
                float distortionX = fbm(uv * 1.5 + float2(t, t * 0.5)) * 0.3;
                float distortionY = fbm(uv * 1.5 - float2(t * 0.5, t)) * 0.3;
                
                float2 distortedUV = uv + float2(wave1 + distortionX, wave2 + distortionY) - 0.15;
                
                // 2. Sliding Horizontal Bands (3 Colors)
                // We use the severely distorted Y coordinate to create the wavy bands that slide slowly.
                // Subtracting time makes the waves slide up/down relative to the view.
                float v = distortedUV.y - t * 0.2; 
                
                // Map the sliding Y value [0, 1] into a looping cycle [0, 3) 
                float bandPos = fmod(abs(v * 2.0), 3.0);
                
                // Smooth interpolation between the three colors based on the band position
                float4 baseColor;
                if (bandPos < 1.0) {
                    baseColor = mix(uniforms.color1, uniforms.color2, smoothstep(0.0, 1.0, bandPos));
                } else if (bandPos < 2.0) {
                    baseColor = mix(uniforms.color2, uniforms.color3, smoothstep(1.0, 2.0, bandPos));
                } else {
                    baseColor = mix(uniforms.color3, uniforms.color1, smoothstep(2.0, 3.0, bandPos));
                }
                
                float3 finalRGB = baseColor.rgb;

                // 揺らぎだけなので一定アルファ
                float alpha = 0.75;

                return float4(finalRGB, alpha);
            }
            """
            
            do {
                let library = try device.makeLibrary(source: shaderSource, options: nil)
                guard let vertexFunction = library.makeFunction(name: "vertex_main"),
                      let fragmentFunction = library.makeFunction(name: "fragment_main") else {
                    print("Failed to load Metal functions from string.")
                    return
                }
                
                let pipelineDescriptor = MTLRenderPipelineDescriptor()
                pipelineDescriptor.vertexFunction = vertexFunction
                pipelineDescriptor.fragmentFunction = fragmentFunction
                pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
                // Enabling alpha blending
                pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
                pipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
                pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
                pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
                pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
                
                self.pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                print("Metal compilation error: \\(error)")
            }
        }

        struct Uniforms {
            var time: Float
            var padding: Float = 0.0 // explicit padding for float2 alignment
            var resolution: SIMD2<Float>
            var color1: SIMD4<Float>
            var color2: SIMD4<Float>
            var color3: SIMD4<Float>
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let pipelineState = pipelineState,
                  let commandQueue = commandQueue,
                  let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                return
            }
            
            time += (1.0 / 60.0) * speed

            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            
            var uniforms = Uniforms(
                time: time + basePhase,
                resolution: SIMD2<Float>(Float(view.bounds.width), Float(view.bounds.height)),
                color1: self.color1,
                color2: self.color2,
                color3: self.color3
            )
            renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
            
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    }
}

private extension Color {
    func toVector() -> SIMD4<Float> {
        guard let cgColor = self.cgColor, let components = cgColor.components else {
            return SIMD4<Float>(0,0,0,1)
        }
        let r = Float(components[0])
        let g = Float(components.count > 1 ? components[1] : components[0])
        let b = Float(components.count > 2 ? components[2] : components[0])
        let a = Float(components.count > 3 ? components[3] : 1.0)
        return SIMD4<Float>(r, g, b, a)
    }
}
