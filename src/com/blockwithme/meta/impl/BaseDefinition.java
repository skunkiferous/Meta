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

/**
 * Base class for all definitions.
 *
 * @author monster
 */
public abstract class BaseDefinition<D extends Definition<D>> extends
        BaseConfigurable<D> implements Definition<D> {

    /* (non-Javadoc)
     * @see java.lang.Comparable#compareTo(java.lang.Object)
     */
    @Override
    public int compareTo(final D o) {
        return name().compareTo(o.name());
    }

    /** */
    @Override
    public int hashCode() {
        return name().hashCode();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Definition#name()
     */
    @Override
    public String name() {
        return (String) getProperty("name");
    }

    /** Set the name */
    public D name(final String value) {
        return setProperty("name", value);
    }

    /** Returns the "unique key" to this definition. */
    public abstract String key();

    /** Called, after the initial values have been set. */
    @Override
    protected void _postInit() {
        checkProp("name", String.class);
        super._postInit();
    }
}
