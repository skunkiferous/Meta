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

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import com.blockwithme.meta.Statics;
import com.blockwithme.meta.types.impl.BundleComparator;
import com.tinkerpop.blueprints.Vertex;
import com.tinkerpop.frames.modules.javahandler.JavaHandlerImpl;

/**
 * @author monster
 *
 */
public abstract class Feature$Impl implements JavaHandlerImpl<Vertex>, Feature {
    /** Returns all the currently available bundles within this application. */
    @Override
    public Bundle[] bundles() {
        final Bundle rootBundle = getBundle();
        final List<Bundle> todo = new ArrayList<>();
        final List<Bundle> done = new ArrayList<>();
        todo.add(rootBundle);
        while (!todo.isEmpty()) {
            final Bundle bundle = todo.remove(todo.size() - 1);
            done.add(bundle);
            for (final Dependency dep : bundle.getDependencies()) {
                final Bundle otherBundle = dep.getBundle();
                if (!todo.contains(otherBundle) && !done.contains(otherBundle)) {
                    todo.add(otherBundle);
                }
            }
        }
        return done.toArray(new Bundle[done.size()]);
    }

    /**
     * Returns the bundles with the given name, if any.
     */
    @Override
    public Bundle findBundle(final String name) {
        for (final Bundle bundle : bundles()) {
            if (name.equals(bundle.getName())) {
                return bundle;
            }
        }
        return null;
    }

    /**
     * Returns the shortest distance from the root bundle (0) through
     * dependencies. Returns Integer.MAX_VALUE when unknown/not found.
     */
    @Override
    public int distanceFromRoot(final Bundle bundle) {
        return Statics.distanceFromRoot(this, bundle);
    }

    /** Returns a Bundle Comparator. */
    @Override
    public Comparator<Bundle> getBundleComparator() {
        return new BundleComparator(this);
    }
}
