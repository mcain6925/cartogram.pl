
//
//	Data that applies to the 3D scene
//

var theta = 3.14159 * 1;
var camera_rad = 500;
var camera_x =  camera_rad * Math.sin(theta);
var camera_y =  camera_rad * Math.cos(theta);
var camera_z =  650;
var light1;
var light2;
var light_theta;
var light_rad;
var light_x;
var light_y;
var light_z;
var container;
var renderer;
var scene;
var camera;
var light;
var width, height;
var polling_interval;
var render_flag = 0;
var line_material;
var utah = [
	[ -104.03,  49.80 ],
	[ -101.65,  61.06 ],
	[ -101.05,  63.86 ],
	[ -96.29,  86.17 ],
	[ -94.25,  95.79 ],
	[ -93.10, 101.04 ],
	[ -88.17, 124.07 ],
	[ -82.57, 150.00 ],
	[ -62.43, 145.73 ],
	[ -46.24, 142.31 ],
	[ -45.33, 142.21 ],
	[ -33.67, 139.85 ],
	[ -25.08, 138.10 ],
	[ -27.10, 127.21 ],
	[ -28.62, 118.85 ],
	[ -29.84, 112.01 ],
	[ -10.43, 108.53 ],
	[  -9.23, 108.31 ],
	[   9.57, 105.18 ],
	[   8.26,  96.45 ],
	[   6.32,  84.56 ],
	[   4.08,  70.08 ],
	[   3.51,  66.43 ],
	[   2.92,  62.31 ],
	[  -0.55,  39.64 ],
	[  -1.56,  33.11 ],
	[  -1.67,  30.66 ],
	[  -2.70,  23.71 ],
	[  -3.74,  17.01 ],
	[  -6.24,   0.43 ],
	[ -26.08,   3.57 ],
	[ -35.57,   5.21 ],
	[ -36.19,   5.64 ],
	[ -41.52,   6.56 ],
	[ -54.35,   8.89 ],
	[ -72.67,  12.26 ],
	[ -78.99,  13.60 ],
	[ -86.40,  15.07 ],
	[ -110.04,  20.15 ],
	[ -106.91,  35.80 ],
	[ -104.03,  49.80 ],
];
var new_mexico = [
	[ -23.10, -118.55 ],
	[ -21.93, -109.74 ],
	[ -20.39, -98.64 ],
	[ -18.29, -83.55 ],
	[ -15.29, -62.44 ],
	[ -13.90, -52.97 ],
	[ -10.03, -25.73 ],
	[  -6.24,   0.43 ],
	[   7.92,  -1.69 ],
	[  26.79,  -4.44 ],
	[  28.08,  -4.65 ],
	[  39.01,  -6.09 ],
	[  39.59,  -6.43 ],
	[  47.78,  -7.43 ],
	[  57.89,  -8.67 ],
	[  63.76,  -9.31 ],
	[  74.29, -10.57 ],
	[  75.71, -10.71 ],
	[ 100.03, -13.21 ],
	[ 119.39, -14.85 ],
	[ 121.08, -15.02 ],
	[ 120.04, -28.33 ],
	[ 119.40, -28.30 ],
	[ 118.57, -39.76 ],
	[ 117.96, -48.00 ],
	[ 117.73, -51.12 ],
	[ 116.74, -62.84 ],
	[ 116.33, -68.42 ],
	[ 115.94, -74.19 ],
	[ 114.91, -85.66 ],
	[ 113.87, -98.29 ],
	[ 113.24, -105.11 ],
	[ 112.77, -110.03 ],
	[ 111.80, -121.14 ],
	[ 110.70, -132.60 ],
	[ 109.97, -143.89 ],
	[ 109.74, -146.06 ],
	[ 103.57, -145.47 ],
	[  94.64, -144.62 ],
	[  88.96, -144.09 ],
	[  88.11, -143.98 ],
	[  69.39, -142.21 ],
	[  67.79, -142.01 ],
	[  43.51, -139.36 ],
	[  35.09, -138.37 ],
	[  29.59, -137.67 ],
	[  28.94, -138.14 ],
	[  29.31, -138.40 ],
	[  29.12, -139.92 ],
	[  28.83, -140.38 ],
	[  29.31, -141.78 ],
	[  29.26, -142.48 ],
	[  30.87, -143.52 ],
	[  14.15, -141.39 ],
	[  -6.47, -138.47 ],
	[  -8.09, -150.00 ],
	[ -26.88, -147.20 ],
	[ -23.10, -118.55 ],
];
var arizona = [
	[ -140.69, -80.60 ],
	[ -141.48, -80.17 ],
	[ -142.63, -80.18 ],
	[ -143.12, -79.89 ],
	[ -143.31, -79.56 ],
	[ -143.74, -79.61 ],
	[ -144.48, -77.91 ],
	[ -144.30, -77.22 ],
	[ -143.39, -76.21 ],
	[ -143.14, -74.72 ],
	[ -143.23, -74.30 ],
	[ -142.86, -73.60 ],
	[ -143.92, -72.34 ],
	[ -142.99, -71.29 ],
	[ -143.15, -69.67 ],
	[ -141.38, -69.85 ],
	[ -140.96, -69.39 ],
	[ -140.61, -68.68 ],
	[ -140.02, -68.34 ],
	[ -139.66, -67.79 ],
	[ -138.16, -66.75 ],
	[ -138.29, -66.17 ],
	[ -137.80, -65.16 ],
	[ -137.53, -64.04 ],
	[ -137.68, -63.54 ],
	[ -136.67, -63.07 ],
	[ -136.81, -62.10 ],
	[ -136.54, -61.39 ],
	[ -136.62, -59.90 ],
	[ -136.33, -59.53 ],
	[ -136.42, -58.94 ],
	[ -135.61, -57.44 ],
	[ -136.06, -56.60 ],
	[ -135.84, -56.31 ],
	[ -133.59, -55.06 ],
	[ -133.24, -53.82 ],
	[ -132.81, -53.26 ],
	[ -130.74, -52.67 ],
	[ -129.79, -52.07 ],
	[ -128.65, -51.92 ],
	[ -126.40, -50.23 ],
	[ -125.85, -50.20 ],
	[ -125.82, -49.07 ],
	[ -126.12, -48.41 ],
	[ -126.59, -47.53 ],
	[ -128.00, -46.13 ],
	[ -128.51, -45.83 ],
	[ -128.81, -45.13 ],
	[ -129.34, -44.49 ],
	[ -130.26, -44.16 ],
	[ -130.32, -43.67 ],
	[ -129.86, -42.16 ],
	[ -130.32, -40.78 ],
	[ -130.77, -40.27 ],
	[ -130.45, -40.02 ],
	[ -130.85, -37.24 ],
	[ -131.36, -36.18 ],
	[ -131.92, -35.94 ],
	[ -132.22, -35.58 ],
	[ -132.44, -33.58 ],
	[ -133.42, -32.17 ],
	[ -133.25, -31.01 ],
	[ -132.92, -30.44 ],
	[ -132.88, -28.98 ],
	[ -132.63, -29.00 ],
	[ -132.68, -27.83 ],
	[ -131.69, -27.12 ],
	[ -132.32, -25.82 ],
	[ -132.04, -25.47 ],
	[ -131.12, -25.72 ],
	[ -130.86, -25.57 ],
	[ -130.44, -24.74 ],
	[ -130.17, -23.56 ],
	[ -130.32, -21.23 ],
	[ -130.07, -19.83 ],
	[ -130.75, -17.16 ],
	[ -130.97, -15.35 ],
	[ -130.34, -14.66 ],
	[ -130.20, -13.65 ],
	[ -129.78, -13.02 ],
	[ -129.89, -12.04 ],
	[ -130.14, -11.72 ],
	[ -129.87, -10.78 ],
	[ -130.16,  -9.65 ],
	[ -129.86,  -8.84 ],
	[ -129.57,  -6.66 ],
	[ -128.87,  -6.18 ],
	[ -128.80,  -5.94 ],
	[ -129.42,  -4.95 ],
	[ -129.78,  -2.80 ],
	[ -129.13,  -1.62 ],
	[ -129.25,  -0.99 ],
	[ -129.08,  -0.29 ],
	[ -128.66,   0.13 ],
	[ -126.56,   0.65 ],
	[ -126.11,   0.45 ],
	[ -124.59,   0.56 ],
	[ -123.42,  -0.53 ],
	[ -122.97,  -0.73 ],
	[ -121.49,  -0.25 ],
	[ -120.80,  -0.77 ],
	[ -120.35,  -1.58 ],
	[ -120.23,  -2.27 ],
	[ -120.44,  -2.90 ],
	[ -119.12,  -4.38 ],
	[ -118.57,  -4.53 ],
	[ -116.82,  -4.26 ],
	[ -115.96,  -2.30 ],
	[ -114.27,  -0.69 ],
	[ -113.99,  -0.16 ],
	[ -110.85,  16.13 ],
	[ -110.04,  20.15 ],
	[ -86.40,  15.07 ],
	[ -78.99,  13.60 ],
	[ -72.67,  12.26 ],
	[ -54.35,   8.89 ],
	[ -41.52,   6.56 ],
	[ -36.19,   5.64 ],
	[ -35.57,   5.21 ],
	[ -26.08,   3.57 ],
	[  -6.24,   0.43 ],
	[ -10.03, -25.73 ],
	[ -13.90, -52.97 ],
	[ -15.29, -62.44 ],
	[ -18.29, -83.55 ],
	[ -20.39, -98.64 ],
	[ -21.93, -109.74 ],
	[ -23.10, -118.55 ],
	[ -26.88, -147.20 ],
	[ -58.49, -142.20 ],
	[ -72.36, -139.82 ],
	[ -78.63, -136.12 ],
	[ -119.42, -111.74 ],
	[ -150.00, -93.13 ],
	[ -149.07, -89.85 ],
	[ -146.63, -87.56 ],
	[ -146.36, -87.24 ],
	[ -145.92, -87.17 ],
	[ -144.03, -88.00 ],
	[ -143.97, -87.76 ],
	[ -143.28, -87.87 ],
	[ -143.23, -87.57 ],
	[ -142.98, -87.63 ],
	[ -142.93, -87.32 ],
	[ -142.53, -87.41 ],
	[ -142.48, -87.13 ],
	[ -142.20, -87.19 ],
	[ -142.22, -86.74 ],
	[ -141.92, -86.21 ],
	[ -140.33, -85.61 ],
	[ -140.20, -83.19 ],
	[ -139.81, -82.14 ],
	[ -140.69, -80.60 ],
];

//
//	Initialization stuff, in three parts basically
//	Third test for WebGL and if available render the 3D scene
//	Finally, set various timer interrupts everything needs to run
//

window.onload = init;

function init() {
	var webgl_canvas;
	var webgl_flag = undefined;

	webgl_canvas = document.getElementById("webgl_test");
	if (webgl_canvas) {
		webgl_flag = webgl_canvas.getContext("webgl") || webgl_canvas.getContext("experimental-webgl");
		webgl_flag = (webgl_flag) ? 1 : 0;
	}
	if (!webgl_flag) {
		alert("WebGL not available");
	}
	else {
		init_3d();
	}
	polling_interval = window.setInterval(polling_loop, 50);
}


//
//	Initializing the 3D stuff for three.js is rather involved
//	Note that some of this stuf -- a considerable amount, actually, is specific to version 58 of three.js
//

function init_3d() {
	var material;
	var geometry;
	var material;
	var object;
	var wireframe_material;
	var extrude_shape;
	var extrude_geometry;
	var extrude_mesh;
	var points;

//	Preliminaries -- container, renderer, scene, camera, lights
	height = 350;
	width  = 400;
	container = document.getElementById('3d');
	renderer = new THREE.WebGLRenderer({ antialias:true });
	renderer.setSize(width, height);
	container.appendChild(renderer.domElement);
	scene = new THREE.Scene();
	camera = new THREE.PerspectiveCamera(45, width/height, 1, 1000);
	camera.up.set(0,0,1);
	camera.position.set(camera_x, camera_y, camera_z);
	camera.lookAt(scene.position);

	light = new THREE.DirectionalLight(0xffffff, 0.5);
	light.position.set(0,0,600);
	scene.add(light);

	light1 = new THREE.PointLight(0xaaaaaa, 3, 0, 2);
	light_theta = theta + Math.PI / 6;
	light_rad = 600;
	light_x = light_rad * Math.sin(light_theta);
	light_y = light_rad * Math.cos(light_theta);
	light_z = camera_z + 200;
	light1.position.set(light_x, light_y, light_z);
	scene.add(light1);

	light2 = new THREE.PointLight(0xaaaaaa, 1, 0, 2);
	light_theta = theta - Math.PI / 6;
	light_x = light_rad * Math.sin(light_theta);
	light_y = light_rad * Math.cos(light_theta);
	light2.position.set(light_x, light_y, light_z);
	scene.add(light2);

//	Draw the base, then draw the assorted objects that sit on it
	draw_base(225, 30, 0xaaaaaa);
	line_material = new THREE.LineBasicMaterial({color:0x333333, linewidth:1});
	add_funky(utah, 160, 0x00ff00);
	add_funky(arizona, 110, 0xcccc00);
	add_funky(new_mexico, 55, 0xff0000);

//	Event handlers
	if (document.addEventListener) {
		document.addEventListener('keydown', key_down, false);
	}
	if (document.attachEvent) {
		container.attachEvent('onkeydown', key_down);
	}

//	Misc
	render_flag = 1;
}

function rotate_around_world_axis(object, axis, radians) {
	rotWorldMatrix = new THREE.Matrix4();
	rotWorldMatrix.makeRotationAxis(axis.normalize(), radians);
	rotWorldMatrix.multiply(object.matrix);
	object.matrix = rotWorldMatrix;
	object.rotation.setEulerFromRotationMatrix(object.matrix, "XYZ");
}

function draw_base(size, step, color) {
	var geometry;
	var material;
	var plane;

	geometry = new THREE.PlaneGeometry(2*size, 2*size, step, step);
	material = new THREE.MeshBasicMaterial({
		color:color,
		wireframe:true
	});
	plane = new THREE.Mesh(geometry, material);
	scene.add(plane);
}

function add_funky(points, height, color) {
	var geometry, shape, object, mesh;
	var i;

	geometry = new THREE.Geometry();
	shape = new THREE.Shape();
	shape.moveTo(points[0][0], points[0][1]);
	geometry.vertices.push(new THREE.Vector3(points[0][0], points[0][1], height));
	for (i=1; i<points.length; i++) {
		shape.moveTo(points[i][0], points[i][1]);
		geometry.vertices.push(new THREE.Vector3(points[i][0], points[i][1], height));
	}
	object = new THREE.Line(geometry, line_material);
	scene.add(object);
	geometry = new THREE.ExtrudeGeometry(shape, {amount:height, bevelEnabled:false});
	mesh = new THREE.Mesh(geometry, new THREE.MeshLambertMaterial({color:color, transparent:true, opacity:0.8}));
	scene.add(mesh);
}

function add_cylinder(radius, x, y, amount, color) {
	var points = [];
	var x_point;
	var y_point;
	var angle;
	var i;

	x_point = x + radius * Math.cos(0);
	y_point = y + radius * Math.sin(0);
	points.push([x_point, y_point]);
	angle = 2 * Math.PI / 32;
	for (i=1; i<=32; i++) {
		x_point = x + radius * Math.cos(angle*i);
		y_point = y + radius * Math.sin(angle*i);
		points.push([x_point, y_point]);
	}
	add_funky(points, 100, color);
}

function add_star(cx, cy, radius, amount, color) {
	var points = [];
	var angle;
	var x;
	var y;
	var i;

	angle = Math.PI / 2.0;
	x = cx + radius * Math.cos(angle);
	y = cy + radius * Math.sin(angle);
	points.push([x,y]);
	for (i=0; i<5; i++) {
		angle += 0.2 * Math.PI;
		x = cx + (radius * 0.375) * Math.cos(angle);
		y = cy + (radius * 0.375) * Math.sin(angle);
		points.push([x,y]);
		angle += 0.2 * Math.PI;
		x = cx + radius * Math.cos(angle);
		y = cy + radius * Math.sin(angle);
		points.push([x,y]);
	}
	add_funky(points, amount, color);
}

function polling_loop() {

	if (render_flag) {
		renderer.render(scene, camera);
		render_flag = 0;
	}
}


//
//	Functions to handle the 3D scene including event handler functons for the 3D scene
//

function key_down(event) {
	switch (event.keyCode) {
		case 37:
			rotate_scene('left');
			event.preventDefault();
			break;
		case 39:
			rotate_scene('right');
			event.preventDefault();
			break;
	}
}

function rotate_scene(dir) {
	if (dir == 'left') {
		theta -= 0.025;
		light_theta -= 0.025;
	}
	if (dir == 'right') {
		theta += 0.025;
		light_theta += 0.025;
	}
  	camera_x =  camera_rad * Math.sin(theta);
  	camera_y =  camera_rad * Math.cos(theta);
	camera.position.set(camera_x, camera_y, camera_z);
	camera.lookAt(scene.position);

	light_theta = theta + Math.PI / 6;
	light_rad = 600;
	light_x = light_rad * Math.sin(light_theta);
	light_y = light_rad * Math.cos(light_theta);
	light_z = camera_z + 200;
	light1.position.set(light_x, light_y, light_z);

	light_theta = theta - Math.PI / 6;
	light_rad = 600;
	light_x = light_rad * Math.sin(light_theta);
	light_y = light_rad * Math.cos(light_theta);
	light_z = camera_z + 200;
	light2.position.set(light_x, light_y, light_z);

	render_flag = 1;
}
