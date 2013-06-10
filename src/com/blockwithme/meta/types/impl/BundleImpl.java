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
import java.util.concurrent.CopyOnWriteArrayList;
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

    /** Empty Application array */
    private static final Application[] NO_USER = new Application[0];

    /** The users. Thread safe. */
    private final CopyOnWriteArrayList<Application> users = new CopyOnWriteArrayList<>();

    /** The Bundle Lifecycle */
    private final AtomicReference<BundleLifecycle> lifecycle = new AtomicReference<BundleLifecycle>();

    /** Constructor */
    public BundleImpl() {
        setProperty("lifecycle", lifecycle);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#version()
     */
    @Override
    public String version() {
        return (String) getProperty("version");
    }

    /** Sets the version */
    public BundleImpl version(final String theVersion) {
        return (BundleImpl) setProperty("version", theVersion);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#versionAsInt()
     */
    @Override
    public int versionAsInt() {
        return (Integer) getProperty("versionAsInt");
    }

    /** Sets the versionAsInt */
    public BundleImpl versionAsInt(final String theVersionAsInt) {
        return (BundleImpl) setProperty("versionAsInt", theVersionAsInt);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#types()
     */
    @Override
    public Type[] types() {
        return (Type[]) getProperty("types");
    }

    /** Sets the types */
    public BundleImpl types(final Type[] theTypes) {
        return (BundleImpl) setProperty("types", theTypes);
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
        return (Dependency[]) getProperty("dependencies");
    }

    /** Sets the dependencies */
    public BundleImpl dependencies(final Dependency[] theDependencies) {
        return (BundleImpl) setProperty("dependencies", theDependencies);
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
        return (Service[]) getProperty("services");
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#findService(java.lang.String)
     */
    @Override
    public Service findService(final String name) {
        return findDefinition("services", name);
    }

    /** Adds a user to the list. */
    public BundleImpl addUser(final Application user) {
        users.addIfAbsent(user);
        return this;
    }

    /** Removes a user from the list. */
    public BundleImpl removeUser(final Application user) {
        users.remove(user);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Bundle#queryUsers()
     */
    @Override
    public Application[] users() {
        // Must always pass empty array, otherwise something might get removed
        // while calling, and we end up with nulls in the return value.
        return users.toArray(NO_USER);
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
        checkProp("version", String.class);
        checkProp("versionAsInt", Integer.class);
        checkProp("dependencies", Dependency[].class);
        checkProp("types", Type[].class);
        checkProp("services", Service[].class);
        super._postInit();
        postInit(dependencies());
        postInit(types());
    }
}
