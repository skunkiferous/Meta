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
import com.blockwithme.meta.infrastructure.Application;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.BundleLifecycle;
import com.blockwithme.meta.types.Dependency;
import com.blockwithme.meta.types.Service;
import com.blockwithme.meta.types.Type;

/**
 * @author monster
 *
 */
public class BundleImpl extends BaseDefinition<Bundle> implements Bundle {

    /** The version */
    private final String version;

    /** The Bundle Lifecycle */
    private final AtomicReference<BundleLifecycle> lifecycle = new AtomicReference<BundleLifecycle>();

    /** Constructor */
    public BundleImpl(final Application theApp, final String theName,
            final String theVersion) {
        super(theApp, theName);
        version = Objects.requireNonNull(theVersion, "theVersion");
        setProperty(this, Long.MIN_VALUE, "lifecycle", lifecycle);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#version()
     */
    @Override
    public String version() {
        return version;
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
        return (Type[]) getProperty(null, "types");
    }

    /** Sets the types */
    public BundleImpl types(final Type[] theTypes) {
        return (BundleImpl) setProperty(this, Long.MIN_VALUE, "types", theTypes);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#findType(java.lang.String)
     */
    @Override
    public Type findType(final String name) {
        for (final Type type : types()) {
            if (name.equals(type.name())) {
                return type;
            }
        }
        return null;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#dependencies()
     */
    @Override
    public Dependency[] dependencies() {
        return (Dependency[]) getProperty(null, "dependencies");
    }

    /** Sets the dependencies */
    public BundleImpl dependencies(final Dependency[] theDependencies) {
        return (BundleImpl) setProperty(this, Long.MIN_VALUE, "dependencies",
                theDependencies);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#findDependency(java.lang.String)
     */
    @Override
    public Dependency findDependency(final String name) {
        for (final Dependency dep : dependencies()) {
            if (name.equals(dep.name())) {
                return dep;
            }
        }
        return null;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#services()
     */
    @Override
    public Service[] services() {
        return (Service[]) getProperty(null, "services");
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#findService(java.lang.String)
     */
    @Override
    public Service findService(final String name) {
        return findDefinition(Long.MIN_VALUE, "services", name);
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

    /** Returns the "unique key" to this definition. */
    @Override
    public String key() {
        return name() + "|" + version();
    }

    /** Called, after the initial values have been set. */
    @Override
    protected void _postInit() {
        checkProp("dependencies", Dependency[].class);
        checkProp("types", Type[].class);
        checkProp("services", Service[].class);
        super._postInit();
        postInit(dependencies());
        postInit(types());
    }
}
