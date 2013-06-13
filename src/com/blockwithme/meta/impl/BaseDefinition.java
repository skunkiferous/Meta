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

import com.blockwithme.meta.Definition;
import com.blockwithme.meta.infrastructure.Application;

/**
 * Base class for all definitions.
 *
 * @author monster
 */
public abstract class BaseDefinition<D extends Definition<D>> extends
        BaseConfigurable<D> implements Definition<D> {

    /** The name */
    private final String name;

    protected BaseDefinition(final Application theApp, final String theName) {
        super(theApp);
        name = Objects.requireNonNull(theName, "theName");
    }

    @Override
    public String[] properties() {
        final String[] result = properties(1);
        result[result.length - 1] = "name";
        return result;
    }

    /* (non-Javadoc)
     * @see java.lang.Comparable#compareTo(java.lang.Object)
     */
    @Override
    public int compareTo(final D o) {
        return name.compareTo(o.name());
    }

    /** */
    @Override
    public int hashCode() {
        return name.hashCode();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Definition#name()
     */
    @Override
    public String name() {
        return name;
    }

    @Override
    public Object getProperty(final Long time, final String name) {
        return "name".equals(name) ? this.name : super.getProperty(time, name);
    }

    /** Returns the "unique key" to this definition. */
    public abstract String key();
}
