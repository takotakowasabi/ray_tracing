// 物体のインタフェース
interface Intersectable {
  Intersection intersect(Ray ray);
}

// 球
class Sphere implements Intersectable {
  Vec center;         // 中心座標
  float radius;       // 半径
  Material material;  // マテリアル

  Sphere(Vec center, float radius, Material material) {
    this.center   = center;
    this.radius   = radius;
    this.material = material;
  }

  Intersection intersect(Ray ray) {
    Intersection isect = new Intersection();
    Vec v = ray.origin.sub(this.center);
    float b = ray.dir.dot(v);
    float c = v.dot(v) - sq(this.radius);
    float d = b * b - c;
    if (d >= 0) {
      float s = sqrt(d);
      float t = -b - s;
      if (t <= 0) { t = -b + s; }
      if (0 < t) {
        isect.t = t;
        isect.p = ray.origin.add(ray.dir.scale(t));
        isect.n = isect.p.sub(this.center).normalize();
        isect.material = this.material;
      }
    }
    return isect;
  }
}

// 無限平面
class Plane implements Intersectable {
  Vec n;              // 面法線 (a, b, c)
  float d;            // 原点からの距離 (平面の方程式 ax + by + cz + d = 0)
  Material material;  // マテリアル

  // 面法線n、点pを通る平面
  Plane(Vec p, Vec n, Material material) {
    this.n = n.normalize();
    this.d = -p.dot(this.n);
    this.material = material;
  }

  Intersection intersect(Ray ray) {
    Intersection isect = new Intersection();
    float v = this.n.dot(ray.dir);
    float t = -(this.n.dot(ray.origin) + this.d) / v;
    if (0 < t) {
      isect.t = t;
      isect.p = ray.origin.add(ray.dir.scale(t));
      isect.n = this.n;
      isect.material = this.material;
    }
    return isect;
  }
}

// チェック柄の物体
class CheckedObj implements Intersectable {
  Intersectable obj;  // 物体の形状・マテリアルその1
  float gridWidth;    // グリッドの幅
  Material material2; // マテリアルその2

  CheckedObj(Intersectable obj, float gridWidth, Material material2) {
    this.obj = obj;
    this.gridWidth = gridWidth;
    this.material2 = material2;
  }

  Intersection intersect(Ray ray) {
    Intersection isect = obj.intersect(ray);

    if (isect.hit()) {
      int i = (
        round(isect.p.x/this.gridWidth) +
        round(isect.p.y/this.gridWidth) +
        round(isect.p.z/this.gridWidth)
      );
      if (i % 2 == 0) {
        isect.material = this.material2;
      }
    }
    return isect;
  }
}

// テクスチャマッピングされた物体
class TexturedObj implements Intersectable {
  Intersectable obj;  // 物体の形状・マテリアルその1
  PImage image; // 画像
  float size; // テクスチャの大きさ
  Vec origin; // テクスチャの原点
  Vec uDir; // テクスチャ座標のu方向
  Vec vDir; // テクスチャ座標のv方向

  Material material; // マテリアル

  TexturedObj(Intersectable obj, PImage image, float size, Vec origin, Vec uDir, Vec vDir) {
    this.obj = obj;
    this.image = image;
    this.size = (size / 3);
    this.origin = origin;
    this.uDir = uDir;
    this.vDir = vDir;
  }

  Intersection intersect(Ray ray) {
    Intersection isect = obj.intersect(ray);

    if (isect.hit()) {
      float u = isect.p.sub(this.origin).dot(this.uDir) / this.size;
      u = floor((u/* - floor(u)*/) * this.image.width);
      float v = -isect.p.sub(this.origin).dot(this.vDir) / this.size;
      v = floor((v/* - floor(v)*/) * this.image.height);

      if(u >= this.image.width || v >= this.image.height || u <= 0 || v <= 0) return isect;
      color c = this.image.get(int(this.image.width - u), int(this.image.height - v));
      
      Material mtl = new Material(new Spectrum(red(c) / 255.0, green(c) / 255.0, blue(c) / 255.0).mul(isect.material.diffuse));
      mtl.reflective = isect.material.reflective;
      mtl.refractive = isect.material.refractive;
      mtl.refractiveIndex = isect.material.refractiveIndex;
      isect.material = mtl;
    }
    return isect;
  }
}
