await interpretate.shared.THREE.load();
const THREE = interpretate.shared.THREE.THREE;
const BufferGeometry = THREE.BufferGeometry;
THREE.Float32BufferAttribute;
THREE.Vector2;
THREE.Vector3;


class VariableTube {

	constructor(material, path, tubularSegments = 64, radius = 1, radialSegments_ = 8, closed = false ) {

        this.geometry = new BufferGeometry();

        let radialSegments = radialSegments_;

        const radialFunction = VariableTube.generateRadial(radius, radialSegments);
        const normalFunction = VariableTube.generateNormal(radius, radialSegments);
        

		// create buffer data

		const frame = VariableTube.generateBufferData(path, radialSegments, radialFunction, normalFunction);

		// build geometry
        //console.log({indices, vertices, radius, radialPoints});
        this.radialSegments = radialSegments;

        this.indices = new THREE.BufferAttribute( new Uint16Array(frame.indices), 1 );
		this.geometry.setIndex( this.indices );
        //this.setDrawRange(0, length-1); 
        this.vertices = new THREE.BufferAttribute( new Float32Array(frame.vertices), 3 );
        this.normals = new THREE.BufferAttribute( new Float32Array(frame.normals), 3 );
		this.geometry.setAttribute( 'position', this.vertices );
        this.geometry.setAttribute( 'normal', this.normals );
        //this.geometry.computeVertexNormals();
		//this.setAttribute( 'normal', new Float32BufferAttribute( normals, 3 ) );
		//this.setAttribute( 'uv', new Float32BufferAttribute( uvs, 2 ) );

		// functions

		
        



        const mesh = new THREE.Mesh(this.geometry, material);
        this.mesh = mesh;

        return this;

    }

    dispose() {
        this.geometry.dispose();
    }

    update(path, radius) {
        const radialFunction = VariableTube.generateRadial(radius, this.radialSegments);
        const normalFunction = VariableTube.generateNormal(radius, this.radialSegments);
       //console.warn(radialFunction());
        //console.warn(this.radialSegments);
        const frame = VariableTube.generateBufferData(path, this.radialSegments, radialFunction, normalFunction);

        if (this.indices.count > frame.indices.length) {

            this.indices.set(new Uint16Array(frame.indices));
            this.vertices.set(new Float32Array(frame.vertices));
            this.normals.set(new Float32Array(frame.normals));
            this.geometry.setDrawRange(0, frame.indices.length-1); 
            //this.geometry.computeVertexNormals();
            this.indices.needsUpdate = true;
            this.vertices.needsUpdate = true;
            this.normals.needsUpdate = true;
            

        } else if (this.indices.count < frame.indices.length) {

            console.warn('Resize buffers!');

            
            this.geometry.dispose();
            this.geometry = new BufferGeometry();
            this.mesh.geometry = this.geometry;

            this.indices = new THREE.BufferAttribute( new Uint16Array(frame.indices.length * 2), 1 );
            this.vertices = new THREE.BufferAttribute( new Float32Array(frame.vertices.length * 2), 3 );
            this.normals = new THREE.BufferAttribute( new Float32Array(frame.normals.length * 2), 3 );

            this.indices.setUsage( THREE.StreamDrawUsage ); //opt for WebGL
            this.vertices.setUsage( THREE.StreamDrawUsage );
            this.normals.setUsage( THREE.StreamDrawUsage );

            this.indices.set(new Uint16Array(frame.indices));
            this.vertices.set(new Float32Array(frame.vertices));
            this.normals.set(new Float32Array(frame.normals));

            this.geometry.setIndex( this.indices );
            this.geometry.setAttribute( 'position', this.vertices );
            this.geometry.setAttribute( 'normal', this.normals );
            //this.geometry.computeVertexNormals();

            this.indices.needsUpdate = true;
            this.vertices.needsUpdate = true;
            this.normals.needsUpdate = true;

        } else {
            this.indices.set(new Uint16Array(frame.indices));
            this.vertices.set(new Float32Array(frame.vertices));
            this.normals.set(new Float32Array(frame.normals));
            //this.geometry.computeVertexNormals();
            this.indices.needsUpdate = true;
            this.vertices.needsUpdate = true;
            this.normals.needsUpdate = true;
        }
    }

    static generateRadial(radius, radialSegments) {
        const nn = [0.,0.];
        const temporalR = [];

        const inc = 2.0*Math.PI / radialSegments;
        const radialPoints = [];

        if (Array.isArray(radius)) {
            for (let i=0; i<= 2.0*Math.PI; i+=inc) {
                nn[0] = Math.cos(i);
                nn[1] = Math.sin(i);

                temporalR.push([...nn]);
            }

            //radialSegments = temporalR.length;

            for (let h=0; h<radius.length; ++h) {
                const scaled = [];
                for (let j=0; j<temporalR.length; ++j) {
                    const i = temporalR[j];
                    //console
                    scaled.push([i[0]*radius[h], i[1]*radius[h]]);
                }

                radialPoints.push(scaled);
            }

  

            return (index) => {return radialPoints[index]}

        } else {
            for (let i=0; i<= 2.0*Math.PI; i+=inc) {
                nn[0] = Math.cos(i);
                nn[1] = Math.sin(i);

                radialPoints.push(nn.map((el => el*radius)));
            }

            //radialSegments = radialPoints.length;
            return () => radialPoints
        }

    }

    static generateNormal(radius, radialSegments) {
        const temporalR = [];
        const nn = [];

        const inc = 2.0*Math.PI / radialSegments;
        const radialPoints = [];

        if (Array.isArray(radius)) {
            for (let i=0; i<= 2.0*Math.PI; i+=inc) {
                nn[0] = Math.cos(i);
                nn[1] = Math.sin(i);

                temporalR.push([...nn]);
            }

            //radialSegments = temporalR.length;

            for (let h=0; h<radius.length-1; ++h) {
                const scaled = [];
                for (let j=0; j<temporalR.length; ++j) {
                    const i = temporalR[j];
                    //console
                    scaled.push([i[0], i[1], radius[h+1] - radius[h]]);
                }

                radialPoints.push(scaled);
            }

            radialPoints.push(radialPoints[radialPoints.length-1]); //last one

  

            return (index) => {return radialPoints[index]}

        } else {
            for (let i=0; i<= 2.0*Math.PI; i+=inc) {

                radialPoints.push([Math.cos(i), Math.sin(i), 0.]);
            }

            //radialSegments = radialPoints.length;
            return () => radialPoints
        }

    }    

    static generateBufferData(path, radialSegments, radialFunction, normalFunction) {

        const vertices = [];
        const normals = [];
        let indices = [];

		const vertex = [0.,0.,0.];
        const normal = [0.,0.,0.];
        const basis = [[1,0,0], [0,1,0], [0,0,1]];
        let p;
        let n;
        let norm;
        let nv = [0.0, 0.0, 0.0];
        let tv = [0.0, 0.0, 0.0];
        let cv = [0.0, 0.0, 0.0];

        let currentIndex = 0;
        let delta;



        function generateLastSegment () {
            p = path[path.length-2];
            n = path[path.length-1];
    
            //get tangent
            tv[0] = n[0]-p[0];
            tv[1] = n[1]-p[1]; 
            tv[2] = n[2]-p[2];
    
            norm = Math.sqrt(tv[0]*tv[0] + tv[1]*tv[1] + tv[2]*tv[2]);
            
    
            if (norm == 0.) {
                return;
            }
    
            delta = norm;
            tv = tv.map((e) => e/norm);
            //get normal

            const minimalDot = basis.map((el) => (el[0]*tv[0] + el[1]*tv[1] + el[2]*tv[2]));
            if (Math.abs(minimalDot[0]) < Math.abs(minimalDot[1]) && Math.abs(minimalDot[0]) < Math.abs(minimalDot[2])) {
                nv[0] = 1.0 - minimalDot[0] * tv[0];
                nv[1] = 0.0 - minimalDot[0] * tv[1];
                nv[2] = 0.0 - minimalDot[0] * tv[2];
            } else if (Math.abs(minimalDot[1]) < Math.abs(minimalDot[2]) && Math.abs(minimalDot[1]) < Math.abs(minimalDot[0])) {
                nv[0] = 0.0 - minimalDot[1] * tv[0];
                nv[1] = 1.0 - minimalDot[1] * tv[1];
                nv[2] = 0.0 - minimalDot[1] * tv[2];
            } else {
                nv[0] = 0.0 - minimalDot[2] * tv[0];
                nv[1] = 0.0 - minimalDot[2] * tv[1];
                nv[2] = 1.0 - minimalDot[2] * tv[2];
            }

            //norm = Math.sqrt(nv[0]*nv[0] + nv[1]*nv[1] + nv[2]*nv[2]);
            //nv = nv.map((e) => e/norm);
    
            //get cross
         
            cv[0] = nv[2] * tv[1] -nv[1] * tv[2];
            cv[1] = nv[0] * tv[2] - nv[2] * tv[0];
            cv[2] = nv[1] * tv[0] - nv[0] * tv[1];
    
            const radialSector = radialFunction(path.length-1);
            const normalSector = normalFunction(path.length-1);
            const len = radialSegments;


    
    
            for (let k=0; k<len; ++k) {
                const secX = radialSector[k][0];
                const secY = radialSector[k][1];
    
                const normX = normalSector[k][0];
                const normY = normalSector[k][1];
                const skew  = -normalSector[k][2] / delta;
                const skewNorm = 1.0/Math.sqrt(1 + skew*skew);
    
                vertex[0] = secX * nv[0] + secY * cv[0] + n[0];
                vertex[1] = secX * nv[1] + secY * cv[1] + n[1]; 
                vertex[2] = secX * nv[2] + secY * cv[2] + n[2];

                normal[0] = (normX * (nv[0] ) + normY * (cv[0] ) + tv[0] * skew) * skewNorm;
                normal[1] = (normX * (nv[1] ) + normY * (cv[1] ) + tv[1] * skew) * skewNorm;
                normal[2] = (normX * (nv[2] ) + normY * (cv[2] ) + tv[2] * skew) * skewNorm;
    
    
       
                vertices.push(...vertex);      
                normals.push(...normal);         
                //normals.push(normX * nv[0] + normY * cv[0], normX * nv[1] + normY * cv[1], normX * nv[2] + normY * cv[2]);
            }
        }
    
        function generateSegment() {
    
            p = path[currentIndex];
            n = path[currentIndex+1];
    
            //get tangent
            tv[0] = n[0]-p[0];
            tv[1] = n[1]-p[1]; 
            tv[2] = n[2]-p[2];
    
            norm = Math.sqrt(tv[0]*tv[0] + tv[1]*tv[1] + tv[2]*tv[2]);
    
            if (norm == 0) {
                currentIndex++;
                indices = indices.slice(0, -(radialSegments * 6 ));
                return;
            }
    
            delta = norm;
            tv = tv.map((e) => e/norm);
            //get normal
            const minimalDot = basis.map((el) => (el[0]*tv[0] + el[1]*tv[1] + el[2]*tv[2]));
            //.error(minimalDot);
            if (Math.abs(minimalDot[0]) <= Math.abs(minimalDot[1]) && Math.abs(minimalDot[0]) <= Math.abs(minimalDot[2])) {
                nv[0] = 1.0 - minimalDot[0] * tv[0];
                nv[1] = 0.0 - minimalDot[0] * tv[1];
                nv[2] = 0.0 - minimalDot[0] * tv[2];
            } else if (Math.abs(minimalDot[1]) <= Math.abs(minimalDot[2]) && Math.abs(minimalDot[1]) <= Math.abs(minimalDot[0])) {
                nv[0] = 0.0 - minimalDot[1] * tv[0];
                nv[1] = 1.0 - minimalDot[1] * tv[1];
                nv[2] = 0.0 - minimalDot[1] * tv[2];
            } else {
                nv[0] = 0.0 - minimalDot[2] * tv[0];
                nv[1] = 0.0 - minimalDot[2] * tv[1];
                nv[2] = 1.0 - minimalDot[2] * tv[2];
            }


            cv[0] = nv[2] * tv[1] -nv[1] * tv[2];
            cv[1] = nv[0] * tv[2] - nv[2] * tv[0];
            cv[2] = nv[1] * tv[0] - nv[0] * tv[1];
    
            let radialSector = radialFunction(currentIndex);
            let normalSector = normalFunction(currentIndex);
       
            const len = radialSegments;
    
            for (let k=0; k<len; ++k) {
                const secX = radialSector[k][0];
                const secY = radialSector[k][1];
    
                const normX = normalSector[k][0];
                const normY = normalSector[k][1];
                const skew  = -normalSector[k][2] / delta;
                const skewNorm = 1.0/Math.sqrt(1 + skew*skew);
    
                vertex[0] = secX * nv[0] + secY * cv[0] + p[0];
                vertex[1] = secX * nv[1] + secY * cv[1] + p[1]; 
                vertex[2] = secX * nv[2] + secY * cv[2] + p[2];

                normal[0] = (normX * (nv[0] ) + normY * (cv[0] ) + tv[0] * skew) * skewNorm;
                normal[1] = (normX * (nv[1] ) + normY * (cv[1] ) + tv[1] * skew) * skewNorm;
                normal[2] = (normX * (nv[2] ) + normY * (cv[2] ) + tv[2] * skew) * skewNorm ;
    
      
                vertices.push(...vertex); 
                normals.push(...normal);
                             
                //normals.push(normX * nv[0] + normY * cv[0], normX * nv[1] + normY * cv[1], normX * nv[2] + normY * cv[2]);
            }

            radialSector = radialFunction(currentIndex+1);
            normalSector = normalFunction(currentIndex+1);
    
            for (let k=0; k<len; ++k) {
                const secX = radialSector[k][0];
                const secY = radialSector[k][1];
    
                const normX = normalSector[k][0];
                const normY = normalSector[k][1];
                const skew  = -normalSector[k][2] / delta;
                const skewNorm = 1.0/Math.sqrt(1 + skew*skew);
    
                vertex[0] = secX * nv[0] + secY * cv[0] + n[0];
                vertex[1] = secX * nv[1] + secY * cv[1] + n[1]; 
                vertex[2] = secX * nv[2] + secY * cv[2] + n[2];

                normal[0] = (normX * (nv[0] ) + normY * (cv[0] ) + tv[0] * skew) * skewNorm;
                normal[1] = (normX * (nv[1] ) + normY * (cv[1] ) + tv[1] * skew) * skewNorm;
                normal[2] = (normX * (nv[2] ) + normY * (cv[2] ) + tv[2] * skew) * skewNorm;

   
    
                vertices.push(...vertex); 
                normals.push(...normal);              
                //normals.push(normX * nv[0] + normY * cv[0], normX * nv[1] + normY * cv[1], normX * nv[2] + normY * cv[2]);
            }
    
    
            for ( let u = 0; u < 2; ++u) {
                const index = currentIndex * 2 + u;
                //if (currentIndex >= path.length -2) return;
    
                for ( let i = 0; i < radialSegments - 1; i ++ ) {
    
                    const a = radialSegments * index + i;
                    const b = radialSegments * (index + 1) + i;
                    const c = radialSegments * index + i + 1;
                    const d = radialSegments * (index + 1) + i + 1;
    
                    // faces
    
                    indices.push( a, c, d );
                    indices.push( a, d, b );
    
                }
    
                const a = radialSegments * index + radialSegments - 1;
                const b = radialSegments * (index + 1) + radialSegments - 1;
                const c = radialSegments * index + 0;
                const d = radialSegments * (index + 1) + 0;
    
                indices.push( a, c, d );
                indices.push( a, d, b );
    
            }
    
            currentIndex++;
        }

        for ( let i = 0; i < path.length-1; i ++ ) {
            generateSegment();
        }

        generateLastSegment();

        return {
            vertices: vertices,
            indices: indices,
            normals: normals
        };
    }
	
}

export { VariableTube };
