// SPDX-License-Identifier: MIT
// Rendering/Shaders.metal
// ブロッホ球描画用のMetalシェーダー

#include <metal_stdlib>
using namespace metal;

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Metal Shading Language (MSL) の基本
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// MSLはC++14ベースのGPUシェーダー言語
//
// 主要な概念:
// - 頂点シェーダー（vertex）: 各頂点の位置を変換
// - フラグメントシェーダー（fragment）: 各ピクセルの色を決定
//
// 修飾子:
// - [[stage_in]]: 前のステージからの入力
// - [[buffer(N)]]: N番目のバッファ
// - [[position]]: 変換後のスクリーン座標
// - constant: GPU上の定数メモリ
//
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// MARK: - 構造体定義

/// 頂点入力（Swift側のVertex構造体と一致させる）
struct VertexIn {
    float3 position [[attribute(0)]];  // 頂点位置
    float3 normal [[attribute(1)]];    // 法線ベクトル
    float4 color [[attribute(2)]];     // 頂点色
};

/// 頂点シェーダーからフラグメントシェーダーへ渡すデータ
struct VertexOut {
    float4 position [[position]];  // スクリーン座標（必須）
    float3 worldPosition;          // ワールド座標
    float3 worldNormal;            // ワールド空間の法線
    float4 color;                  // 色
};

/// ライン用の簡易出力
struct LineVertexOut {
    float4 position [[position]];
    float4 color;
};

/// ユニフォームデータ（Swift側のUniforms構造体と一致させる）
struct Uniforms {
    float4x4 modelMatrix;          // モデル変換
    float4x4 viewMatrix;           // ビュー変換（カメラ）
    float4x4 projectionMatrix;     // 投影変換
    float3x3 normalMatrix;         // 法線変換
    float3 lightDirection;         // ライトの方向
    float3 cameraPosition;         // カメラ位置
};

// MARK: - 球体シェーダー

/// 球体の頂点シェーダー
/// 各頂点を変換してフラグメントシェーダーへ渡す
vertex VertexOut vertexShader(
    uint vertexID [[vertex_id]],                    // 頂点ID
    constant VertexIn* vertices [[buffer(0)]],      // 頂点バッファ
    constant Uniforms& uniforms [[buffer(1)]]       // ユニフォーム
) {
    VertexIn in = vertices[vertexID];
    VertexOut out;
    
    // ワールド座標を計算
    float4 worldPos = uniforms.modelMatrix * float4(in.position, 1.0);
    out.worldPosition = worldPos.xyz;
    
    // スクリーン座標を計算（MVP変換）
    float4 viewPos = uniforms.viewMatrix * worldPos;
    out.position = uniforms.projectionMatrix * viewPos;
    
    // 法線をワールド空間に変換
    out.worldNormal = normalize(uniforms.normalMatrix * in.normal);
    
    // 色をパススルー
    out.color = in.color;
    
    return out;
}

/// 球体のフラグメントシェーダー
/// 各ピクセルの最終色を計算（ライティング含む）
fragment float4 fragmentShader(
    VertexOut in [[stage_in]],                      // 頂点シェーダーからの入力
    constant Uniforms& uniforms [[buffer(0)]]       // ユニフォーム
) {
    // ライティング計算
    float3 normal = normalize(in.worldNormal);
    float3 lightDir = normalize(uniforms.lightDirection);
    
    // 拡散反射（ランバート）
    // dot(N, L) が正なら光が当たっている
    float diffuse = max(dot(normal, lightDir), 0.0);
    
    // 環境光（どこでも少し明るくする）
    float ambient = 0.3;
    
    // フレネル効果（縁が明るくなる）
    // 視線ベクトルと法線の角度に応じて強度変化
    float3 viewDir = normalize(uniforms.cameraPosition - in.worldPosition);
    float fresnel = pow(1.0 - max(dot(viewDir, normal), 0.0), 3.0);
    
    // 最終的な明るさ
    float brightness = ambient + diffuse * 0.5 + fresnel * 0.4;
    
    // 最終色
    float4 finalColor = in.color;
    finalColor.rgb *= brightness;
    
    return finalColor;
}

// MARK: - ライン/ベクトルシェーダー

/// ライン用頂点シェーダー
/// 軸や状態ベクトルの描画に使用
vertex LineVertexOut lineVertexShader(
    uint vertexID [[vertex_id]],
    constant VertexIn* vertices [[buffer(0)]],
    constant Uniforms& uniforms [[buffer(1)]]
) {
    VertexIn in = vertices[vertexID];
    LineVertexOut out;
    
    // MVP変換
    float4 worldPos = uniforms.modelMatrix * float4(in.position, 1.0);
    float4 viewPos = uniforms.viewMatrix * worldPos;
    out.position = uniforms.projectionMatrix * viewPos;
    
    // 色をそのまま使用
    out.color = in.color;
    
    return out;
}

/// ライン用フラグメントシェーダー
/// ライティングなしでそのまま色を出力
fragment float4 lineFragmentShader(
    LineVertexOut in [[stage_in]]
) {
    return in.color;
}
