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

import java.util.Objects;

import com.blockwithme.meta.Configurable;
import com.blockwithme.meta.Definition;
import com.blockwithme.meta.infrastructure.Application;
import com.blockwithme.meta.types.Bundle;

/**
 * Base class for all configurables.
 *
 * @author monster
 */
public class BaseConfigurable<C extends Configurable<C>> implements
        Configurable<C> {

    /** The application. */
    private final Application app;

    /** Are we fully initialized? */
    private boolean initialized;

    /** Checks that the property is set. */
    protected void checkProp(final String name, final Class<?> type) {
        final Object value = getProperty(Long.MAX_VALUE, name);
        if (value == null) {
            throw new IllegalStateException("Property " + name + " not set");
        }
        if ((type != null) && !type.isInstance(value)) {
            throw new IllegalStateException("Property " + name
                    + " has wrong type: " + value.getClass());
        }
    }

    protected BaseConfigurable(final Application theApp) {
        app = Objects.requireNonNull(theApp, "theApp");
    }

    /** Returns the application owning this Configurable. */
    @Override
    public Application app() {
        return app;
    }

    /** toString */
    @Override
    public String toString() {
        String result = getClass().getSimpleName() + "(";
        for (final String prop : properties()) {
            final Object value = getProperty(Long.MAX_VALUE, prop);
            final String valueStr = (value instanceof Definition<?>) ? ((Definition<?>) value)
                    .name() : value.toString();
            result += prop + "=>" + valueStr + ", ";
        }
        return result + ")";
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Definition#properties()
     */
    @Override
    public String[] properties() {
        return properties(0);
    }

    /** Allows adding empty property names slots at the end of the array. */
    protected String[] properties(final int freeslots) {
        return app.properties(this, freeslots);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Definition#getProperty(java.lang.String)
     */
    @Override
    public Object getProperty(final Long time, final String name) {
        return app.getProperty(this, time, name);
    }

    /** Sets a property. */
    @SuppressWarnings("unchecked")
    public C setProperty(final Bundle bundle, final long time,
            final String name, final Object value) {
        app.setProperty(this, bundle, time, name, value);
        return (C) this;
    }

    /** Finds and return the definition with the given name, if any, for a property. */
    protected <E extends Definition<E>> E findDefinition(final Long time,
            final String property, final String name) {
        @SuppressWarnings("unchecked")
        final E[] defs = (E[]) getProperty(time, property);
        if (defs != null) {
            for (final E e : defs) {
                if (name.equals(e.name())) {
                    return e;
                }
            }
        }
        return null;
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
    protected static void postInit(final Configurable<?>... cfgs) {
        for (final Configurable<?> cfg : cfgs) {
            ((BaseConfigurable<?>) cfg).postInit();
        }
    }
}
