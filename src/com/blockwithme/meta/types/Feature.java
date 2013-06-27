/*
 * Copyright (C) 2013 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.meta.types;

import java.util.Comparator;

import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.typed.TypeValue;

/**
 * An feature is a specific *application configuration* of an application,
 * running on a specific execution environment. It is defined by its bundles,
 * and other resources, as well as it's execution environment.
 *
 * Application instances with the same name, refer to the same logical
 * application.
 *
 * @author monster
 */
@TypeValue("Feature")
public interface Feature extends Bundled, Named {
    /** Returns all the currently available bundles within this application. */
    @GremlinGroovy("com.blockwithme.meta.Statics.allBundles(it)")
    Bundle[] bundles();

    /**
     * Returns the bundles with the given name, if any.
     */
    @GremlinGroovy("com.blockwithme.meta.Statics.findBundleByName(it,name)")
    Bundle findBundle(@GremlinParam("name") final String name);

    /**
     * Returns the shortest distance from the root bundle (0) through
     * dependencies. Returns Integer.MAX_VALUE when unknown/not found.
     */
    @GremlinGroovy(value = "com.blockwithme.meta.Statics.distanceFromRoot(it,bundle)", frame = false)
    int distanceFromRoot(@GremlinParam("bundle") final Bundle bundle);

    /** Returns a Bundle Comparator. */
    @GremlinGroovy(value = "com.blockwithme.meta.types.impl.BundleComparator(it)", frame = false)
    Comparator<Bundle> getBundleComparator();
}
