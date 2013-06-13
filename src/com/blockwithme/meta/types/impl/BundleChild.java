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

import com.blockwithme.meta.Definition;
import com.blockwithme.meta.impl.BaseDefinition;
import com.blockwithme.meta.infrastructure.Application;

/**
 * @author monster
 *
 */
public class BundleChild<C extends Definition<C>> extends BaseDefinition<C> {

    /**
     * @param theApp
     * @param theName
     */
    protected BundleChild(final Application theApp, final String theName) {
        super(theApp, theName);
    }

    public BundleImpl bundle() {
        return Objects.requireNonNull((BundleImpl) getProperty(null, "bundle"));
    }

    /** Sets the bundle */
    public C bundle(final BundleImpl value) {
        return setProperty(value, Long.MIN_VALUE, "bundle", value);
    }

    /** Returns the "unique key" to this definition. */
    @Override
    public String key() {
        return bundle().key() + "|" + name();
    }

    /** Called, after the initial values have been set. */
    @Override
    protected void _postInit() {
        checkProp("bundle", BundleImpl.class);
        super._postInit();
        postInit(bundle());
    }
}
