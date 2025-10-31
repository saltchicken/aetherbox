// ‼️ In src/shader.wgsl

struct Time {
    time: f32
}
@group(0) @binding(0)
var<uniform> u_time: Time;

struct CameraUniform {
    view_proj: mat4x4<f32>,
};
@group(1) @binding(0)
var<uniform> camera: CameraUniform;

struct Vertex {
    // ‼️ Changed to vec4
    position: vec4<f32>,
    // ‼️ Changed to vec4
    color: vec4<f32>,
}

@group(2) @binding(0)
var<storage, read> compute_input_buffer: array<Vertex>;
@group(2) @binding(1)
var<storage, read_write> compute_output_buffer: array<Vertex>;

struct VertexInput {
    // ‼️ Changed to vec4
    @location(0) position: vec4<f32>,
    // ‼️ Changed to vec4
    @location(1) color: vec4<f32>,
}

struct VertexOutput {
    @builtin(position) clip_position: vec4<f32>,
    // ‼️ Changed to vec4
    @location(0) color: vec4<f32>,
};

@compute @workgroup_size(256, 1, 1)
fn cs_main(@builtin(global_invocation_id) global_id: vec3<u32>) {
    let idx = global_id.x;

    // ‼️ Get the number of input vertices
    let num_inputs = arrayLength(&compute_input_buffer);

    // ‼️ Bounds check against output AND check if inputs exist
    if idx >= arrayLength(&compute_output_buffer) || num_inputs == 0u {
        return;
    }

    // ‼️ --- This is the new logic ---
    // ‼️ Use modulo to find which input vertex to use as the origin
    let input_idx = idx % num_inputs;

    // ‼️ Use integer division to get a "local" index for the spiral
    // This makes each spiral have its own set of 0, 1, 2, ... indices
    let local_idx = idx / num_inputs;

    // ‼️ Read the correct origin point
    let origin_vert = compute_input_buffer[input_idx];
    
    // --- Create the spiral using the local_idx ---
    let spiral_tightness = 10.0;
    // ‼️ Make radius smaller since we have fewer points per spiral
    let radius_growth = 0.000015;

    let angle = (f32(local_idx) / spiral_tightness) + u_time.time;
    let radius = f32(local_idx) * radius_growth * (1.5 + sin(u_time.time));

    let new_pos = vec4<f32>(
        // ‼️ Start from the origin's position
        origin_vert.position.x + cos(angle) * radius,
        origin_vert.position.y + sin(angle) * radius,
        origin_vert.position.z,
        origin_vert.position.w
    );

    // ‼️ Write the new vertex to the output buffer
    compute_output_buffer[idx].position = new_pos;
    // ‼️ Use the origin's color (so we get red, green, and blue spirals)
    compute_output_buffer[idx].color = origin_vert.color;
}
@vertex
fn vs_main(
    model: VertexInput,
) -> VertexOutput {
    var out: VertexOutput;
    out.color = model.color;
    // ‼️ model.position is already a vec4, no need to construct one
    out.clip_position = camera.view_proj * model.position;
    return out;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let red = (sin(u_time.time) * 0.5) + 0.5;
    // ‼️ Use in.color.a for the alpha channel
    return vec4<f32>(red, in.color.y, in.color.z, in.color.a);
}
