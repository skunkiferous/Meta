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

import com.blockwithme.meta.Configurable;
import com.blockwithme.meta.Definition;
import com.blockwithme.meta.types.Application;
import com.blockwithme.properties.impl.PropertiesImpl;

/**
 * Base class for all configurables.
 *
 * @author monster
 */
public class BaseConfigurable extends PropertiesImpl<Long> implements
        Configurable {

    /** Are we fully initialized? */
    private boolean initialized;

    /** Checks that the property is set. */
    protected void checkProp(final String name, final Class<?> type) {
        get(name, type);
    }

    protected BaseConfigurable(final Configurable parent,
            final String localKey, final Long when) {
        super(parent, localKey, when);
    }

    @Override
    public Configurable parent() {
        return (Configurable) super.parent();
    }

    @Override
    public EverythingImpl root() {
        return (EverythingImpl) super.root();
    }

    /** Returns the application owning this Configurable. */
    @Override
    public Application app() {
        return root().app();
    }

    /** Finds and return the definition with the given name, if any, for a property. */
    protected <E extends Definition<E>> E findDefinition(final String property,
            final String name, final Class<E> type) {
        return find(property + SEPATATOR + name, type);
    }

    /** Called, after the initial values have been set. */
    public final void postInit() {
        if (!initialized) {
            initialized = true;
            _postInit();
        }
    }

    /** Called, after the initial values have been set. */
    protected void _postInit() {
        // NOP
    }

    /** Delegate opstInit. */
    protected static void postInit(final Configurable... cfgs) {
        for (final Configurable cfg : cfgs) {
            ((BaseConfigurable) cfg).postInit();
        }
    }
}
