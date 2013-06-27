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
package com.blockwithme.meta.types.impl;

import java.util.Comparator;
import java.util.Objects;

import com.blockwithme.meta.Statics;
import com.tinkerpop.blueprints.Direction;
import com.tinkerpop.blueprints.Vertex;

/**
 * A bundle comparator compares bundles based on their distance to the root
 * bundle of the application. The smallest/lowest bundle is the root bundle.
 *
 * @author monster
 */
public class BundleComparator implements Comparator<Vertex> {
    /** The application. */
    private final Vertex root;

    /** Creates a BundleComparator */
    public BundleComparator(final Vertex appFeature) {
        this.root = Objects.requireNonNull(appFeature)
                .getVertices(Direction.OUT, "bundle").iterator().next();
    }

    /* (non-Javadoc)
     * @see java.util.Comparator#compare(java.lang.Object, java.lang.Object)
     */
    @Override
    public int compare(final Vertex bundle1, final Vertex bundle2) {
        final int depth1 = Statics.distanceFromRoot(root, bundle1);
        final int depth2 = Statics.distanceFromRoot(root, bundle2);
        int result = (depth1 - depth2);
        if (result == 0) {
            final String name1 = String.valueOf(bundle1.getProperty("name"));
            final String name2 = String.valueOf(bundle2.getProperty("name"));
            result = name1.compareTo(name2);
        }
        return result;
    }
}
