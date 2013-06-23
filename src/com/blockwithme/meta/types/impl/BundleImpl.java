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

import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

import com.blockwithme.meta.Dynamic;
import com.blockwithme.meta.impl.BaseDefinition;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.BundleLifecycle;
import com.blockwithme.meta.types.Dependency;
import com.blockwithme.meta.types.Service;
import com.blockwithme.meta.types.Type;
import com.blockwithme.properties.impl.ImplGraph;

/**
 * @author monster
 *
 */
public class BundleImpl extends BaseDefinition<Bundle> implements Bundle {

    /** The Bundle Lifecycle */
    private final AtomicReference<BundleLifecycle> lifecycle = new AtomicReference<BundleLifecycle>();

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected BundleImpl(final ImplGraph<Long> graph, final String localKey,
            final String theVersion, final Long when) {
        super(graph, localKey, when);
        set(this, "version", Objects.requireNonNull(theVersion, "theVersion"));
        set(this, "lifecycle", lifecycle);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#version()
     */
    @Override
    public String version() {
        return get("version", String.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#versionAsInt()
     */
    @Override
    public int versionAsInt() {
        // TODO
        throw new UnsupportedOperationException();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#types()
     */
    @Override
    public Type[] types() {
        return listChildValues("types", Type.class, false);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#findType(java.lang.String)
     */
    @Override
    public Type findType(final String name) {
        return findDefinition("types", name, Type.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#dependencies()
     */
    @Override
    public Dependency[] dependencies() {
        return listChildValues("dependencies", Dependency.class, false);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#findDependency(java.lang.String)
     */
    @Override
    public Dependency findDependency(final String name) {
        return findDefinition("dependencies", name, Dependency.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#services()
     */
    @Override
    public Service[] services() {
        return listChildValues("services", Service.class, false);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#findService(java.lang.String)
     */
    @Override
    public Service findService(final String name) {
        return findDefinition("services", name, Service.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#lifecycle()
     */
    @Override
    @Dynamic
    public BundleLifecycle lifecycle() {
        return lifecycle.get();
    }

    /** (Mutable) Sets the current lifecycle */
    public BundleImpl lifecycle(final BundleLifecycle value) {
        lifecycle.set(Objects.requireNonNull(value));
        return this;
    }
}
