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
package com.blockwithme.meta.impl;

import com.blockwithme.meta.Definition;
import com.blockwithme.properties.Properties;
import com.blockwithme.properties.impl.ImplGraph;
import com.blockwithme.properties.impl.PropertiesImpl;

/**
 * Base class for all definitions.
 *
 * @author monster
 */
public abstract class BaseDefinition<D extends Definition<D, PARENT, TIME>, PARENT extends Properties<TIME>, TIME extends Comparable<TIME>>
        extends PropertiesImpl<TIME> implements Definition<D, PARENT, TIME> {

    /** Finds and return the definition with the given name, if any, for a property. */
    protected <E extends Definition<E, ?, TIME>> E findDefinition(
            final String property, final String name, final Class<E> type) {
        return find(property + SEPATATOR + name, type);
    }

    /** Checks that the property is set. */
    protected void checkProp(final String name, final Class<?> type) {
        get(name, type);
    }

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected BaseDefinition(final ImplGraph<TIME> graph,
            final String localKey, final TIME when) {
        super(graph, localKey, when);
    }

    /* (non-Javadoc)
     * @see java.lang.Comparable#compareTo(java.lang.Object)
     */
    @Override
    public final int compareTo(final D o) {
        return name().compareTo(o.name());
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Definition#name()
     */
    @Override
    public final String name() {
        return localKey();
    }
}
