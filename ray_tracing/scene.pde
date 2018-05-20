final int DEPTH_MAX = 10; // トレースの最大回数
final float VACUUM_REFRACTIVE_INDEX = 1.0; // 真空の屈折率

// シーン
class Scene {
  // シーン内の物体・光源を格納するArrayListを定義
  ArrayList<Intersectable> objList = new ArrayList<Intersectable>();
  ArrayList<Light> lightList = new ArrayList<Light>();
  
  Scene() {}

  // 形状の追加
  void addIntersectable(Intersectable obj) {
    this.objList.add(obj);
  }

  // 光源の追加
  void addLight(Light light) {
    this.lightList.add(light);
  }

  // レイを撃って色を求める
  Spectrum trace(Ray ray, int depth) {
    // トレースの最大回数に達した場合は計算を中断する
    if (DEPTH_MAX < depth) { return BLACK; }

    // 交点を求める
    Intersection isect = this.findNearestIntersection(ray);
    if (!isect.hit()) { return BLACK; }

    Material m = isect.material;
    Spectrum l = BLACK; // ここに最終的な計算結果が入る

    if (isect.n.dot(ray.dir) < 0) { // 物体に外部から交差した場合
      // 鏡面反射成分
      float ks = m.reflective;
      if (0 < ks) {
        Vec r = ray.dir.reflect(isect.n); // 反射レイを導出
        Spectrum c = trace(new Ray(isect.p, r), depth + 1); // 反射レイを飛ばす
        l = l.add(c.scale(ks).mul(m.diffuse)); // 計算結果に鏡面反射成分を足す
      }
      
      // 屈折成分
      float kt = m.refractive;
      if (0 < kt) {
        Vec r = ray.dir.refract(isect.n, VACUUM_REFRACTIVE_INDEX / m.refractiveIndex); // 屈折レイを導出
        Spectrum c = trace(new Ray(isect.p, r), depth + 1); // 屈折レイを飛ばす
        l = l.add(c.scale(kt).mul(m.diffuse)); // 計算結果に屈折成分を足す
      }

      // 拡散反射成分
      float kd = 1.0 - ks - kt;
      if (0 < kd) {
        Spectrum c = this.lighting(isect.p, isect.n, isect.material); // 拡散反射面の光源計算を行う
        l = l.add(c.scale(kd)); // 計算結果に拡散反射成分を足す
      }
    } else {
      Vec r = ray.dir.refract(isect.n.neg(), m.refractiveIndex / VACUUM_REFRACTIVE_INDEX); // 屈折レイを導出
      l = trace(new Ray(isect.p, r), depth + 1); // 屈折レイを飛ばす
    }

    return l;
  }

  // 一番近くの交点を求める
  Intersection findNearestIntersection(Ray ray) {
    Intersection isect = new Intersection();
    for (int i = 0; i < this.objList.size(); i ++) {
      Intersectable obj = this.objList.get(i);
      Intersection tisect = obj.intersect(ray);
      if ( tisect.t < isect.t ) { isect = tisect; }
    }
    return isect;
  }

  // 光源計算を行う
  Spectrum lighting(Vec p, Vec n, Material m) {
    Spectrum L = BLACK;
    for (int i = 0; i < this.lightList.size(); i ++) {
      Light light = this.lightList.get(i);
      Spectrum c = this.diffuseLighting(p, n, m.diffuse, light.pos, light.power);
      L = L.add(c);
    }
    return L;
  }

  // 拡散反射面の光源計算
  Spectrum diffuseLighting(Vec p, Vec n, Spectrum diffuseColor,
                           Vec lightPos, Spectrum lightPower) {
    Vec v = lightPos.sub(p);
    Vec l = v.normalize();
    float dot = n.dot(l);
    if (dot > 0) {
      // 交点と光源の間にさえぎるものがないか調べる
      if (visible(p, lightPos)) {
        float r = v.len();
        float factor = dot / (4 * PI * r * r);
        return lightPower.scale(factor).mul(diffuseColor);
      }
    }
    return BLACK;
  }

  boolean visible(Vec org, Vec target) {
    Vec v = target.sub(org).normalize();
    // シャドウレイを求める
    Ray shadowRay = new Ray(org.add(v.scale(EPSILON)), v);
    for (int i = 0; i < this.objList.size(); i ++) {
      Intersectable obj = this.objList.get(i);
      // 交差が判明した時点で処理を打ち切る
      if (obj.intersect(shadowRay).t < v.len()) { return false; }
    }
    // シーン中のどの物体ともシャドウレイが交差しない場合にのみtrueを返す
    return true;
  }
}
