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

import java.util.concurrent.atomic.AtomicBoolean;

import com.blockwithme.meta.types.Dependency;
import com.blockwithme.properties.impl.ImplGraph;

/**
 * @author monster
 *
 */
public class DependencyImpl extends BundledDefinition<Dependency> implements
        Dependency {

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected DependencyImpl(final ImplGraph<Long> graph,
            final String localKey, final Long when) {
        super(graph, localKey, when);
    }

    /** Actually using that dependency? */
    private final AtomicBoolean actual = new AtomicBoolean();

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Dependency#minimumVersion()
     */
    @Override
    public int minimumVersion() {
        return get("minimumVersion", Integer.class);
    }

    public DependencyImpl minimumVersion(final int newMinimumVersion) {
        set(bundle(), "minimumVersion", newMinimumVersion);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Dependency#maximumVersion()
     */
    @Override
    public int maximumVersion() {
        return get("maximumVersion", Integer.class);
    }

    public DependencyImpl maximumVersion(final int newMaximumVersion) {
        set(bundle(), "maximumVersion", newMaximumVersion);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Dependency#optional()
     */
    @Override
    public boolean optional() {
        return get("optional", Boolean.class);
    }

    public DependencyImpl optional(final boolean newOptional) {
        set(bundle(), "optional", newOptional);
        return this;
    }

    /** (Mutable) Is this dependency currently use? */
    @Override
    public boolean actual() {
        return actual.get();
    }

    /** (Mutable) Defines if this dependency is currently used */
    public DependencyImpl actual(final boolean value) {
        actual.set(value);
        return this;
    }
}
