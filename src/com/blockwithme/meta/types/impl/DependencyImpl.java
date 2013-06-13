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

import com.blockwithme.meta.infrastructure.Application;
import com.blockwithme.meta.types.Dependency;

/**
 * @author monster
 *
 */
public class DependencyImpl extends BundleChild<Dependency> implements
        Dependency {

    /** Actually using that dependency? */
    private final AtomicBoolean actual = new AtomicBoolean();

    /**
     * @param theApp
     * @param theName
     */
    protected DependencyImpl(final Application theApp, final String theName) {
        super(theApp, theName);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Dependency#minimumVersion()
     */
    @Override
    public int minimumVersion() {
        return (Integer) getProperty(null, "minimumVersion");
    }

    public DependencyImpl minimumVersion(final int newMinimumVersion) {
        return (DependencyImpl) setProperty(bundle(), Long.MIN_VALUE,
                "minimumVersion", newMinimumVersion);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Dependency#maximumVersion()
     */
    @Override
    public int maximumVersion() {
        return (Integer) getProperty(null, "maximumVersion");
    }

    public DependencyImpl maximumVersion(final int newMaximumVersion) {
        return (DependencyImpl) setProperty(bundle(), Long.MIN_VALUE,
                "maximumVersion", newMaximumVersion);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Dependency#optional()
     */
    @Override
    public boolean optional() {
        return (Boolean) getProperty(null, "optional");
    }

    public DependencyImpl optional(final boolean newOptional) {
        return (DependencyImpl) setProperty(bundle(), Long.MIN_VALUE,
                "optional", newOptional);
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

    /** Called, after the initial values have been set. */
    @Override
    protected void _postInit() {
        setProperty(bundle(), Long.MIN_VALUE, "actual", actual);
        checkProp("minimumVersion", Integer.class);
        checkProp("maximumVersion", Integer.class);
        checkProp("optional", Boolean.class);
        super._postInit();
    }
}
