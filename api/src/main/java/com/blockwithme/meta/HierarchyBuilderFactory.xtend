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
    static val CACHE = new HashMap<String, HierarchyBuilder>();

    /** Maps a package name to a hierarchy name. */
    private static def String package2hierarchy(String thePackageName) {
        // TODO Define package-to-hierarchy mapping
        return thePackageName;
    }

    /** Returns the desired HierarchyBuilder instance. */
    def static HierarchyBuilder getHierarchyBuilder(
            String thePackageName) {
        synchronized (CACHE) {
            val key = package2hierarchy(thePackageName);
            var result = CACHE.get(key);
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
    def static <H extends HierarchyBuilder> H registerHierarchyBuilder(
            H theHierarchyBuilder) {
        synchronized (CACHE) {
            val theHierarchyName = Objects.requireNonNull(
                    theHierarchyBuilder, "theHierarchyBuilder").name;
            val result = CACHE.get(theHierarchyName);
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
    def static <E> Type<E> findType(Class<E> clazz) {
        if (clazz == null) {
            return null;
        }
        synchronized (CACHE) {
            val done = new ArrayList<Hierarchy>();
            val unfinished = new ArrayList<HierarchyBuilder>();
            for (hb : CACHE.values()) {
                val h = hb.hierarchy();
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
            for (hierarchy : done) {
                val type = hierarchy.findTypeDirect(clazz);
                if (type != null) {
                    return type;
                }
            }
            // Random search order :(
            for (hierarchyBuilder : unfinished) {
                val type = hierarchyBuilder.findTypeDirect(clazz);
                if (type != null) {
                    return type;
                }
            }
            return null;
        }
    }
}
