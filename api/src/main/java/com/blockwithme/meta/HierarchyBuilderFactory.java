/*
 * Copyright (C) 2014 Sebastien Diot.
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
package com.blockwithme.meta;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * Provides HierarchyBuilder instances.
 *
 * @author monster
 */
public class HierarchyBuilderFactory {
    /** The cache. */
    private static final Map<String, HierarchyBuilder> CACHE = new HashMap<String, HierarchyBuilder>();

    /** Maps a package name to a hierarchy name. */
    private static String package2hierarchy(final String thePackageName) {
        // TODO Define package-to-hierarchy mapping
        return thePackageName;
    }

    /** Returns the desired HierarchyBuilder instance. */
    public static HierarchyBuilder getHierarchyBuilder(
            final String thePackageName) {
        synchronized (CACHE) {
            final String key = package2hierarchy(thePackageName);
            HierarchyBuilder result = CACHE.get(key);
            if (result == null) {
                result = new HierarchyBuilder(key);
                CACHE.put(key, result);
            }
            return result;
        }
    }

    /**
     * Registers a pre-defined HierarchyBuilder.
     *
     * This is usually required when extending the HierarchyBuilder class.
     */
    public static <H extends HierarchyBuilder> H registerHierarchyBuilder(
            final H theHierarchyBuilder) {
        synchronized (CACHE) {
            final String theHierarchyName = Objects.requireNonNull(
                    theHierarchyBuilder, "theHierarchyBuilder").name;
            final HierarchyBuilder result = CACHE.get(theHierarchyName);
            if (result == null) {
                CACHE.put(theHierarchyName, theHierarchyBuilder);
            } else {
                throw new IllegalStateException(theHierarchyName
                        + " already registered!");
            }
            return theHierarchyBuilder;
        }
    }

    /** Search for the given type. */
    public static <E> Type<E> findType(final Class<E> clazz) {
        if (clazz == null) {
            return null;
        }
        synchronized (CACHE) {
            final List<Hierarchy> done = new ArrayList<>();
            final List<HierarchyBuilder> unfinished = new ArrayList<>();
            for (final HierarchyBuilder hb : CACHE.values()) {
                final Hierarchy h = hb.hierarchy();
                if (h != null) {
                    if (!done.contains(h)) {
                        done.add(h);
                    }
                } else {
                    unfinished.add(hb);
                }
            }
            Collections.sort(done);
            Collections.reverse(done);
            for (final Hierarchy hierarchy : done) {
                final Type<E> type = hierarchy.findTypeDirect(clazz);
                if (type != null) {
                    return type;
                }
            }
            // Random search order :(
            for (final HierarchyBuilder hierarchyBuilder : unfinished) {
                final Type<E> type = hierarchyBuilder.findTypeDirect(clazz);
                if (type != null) {
                    return type;
                }
            }
            return null;
        }
    }
}
