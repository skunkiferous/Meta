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

/**
 * Base class for all definitions.
 *
 * @author monster
 */
public abstract class BaseDefinition<D extends Definition<D>> extends
        BaseConfigurable implements Definition<D> {

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected BaseDefinition(final Configurable parent, final String localKey,
            final Long when) {
        super(parent, localKey, when);
    }

    @Override
    public final boolean equals(final Object obj) {
        if ((obj != null) && (getClass() == obj.getClass())) {
            return name().equals(((BaseDefinition<?>) obj).name());
        }
        return false;
    }

    /** */
    @Override
    public final int hashCode() {
        return name().hashCode();
    }

    /* (non-Javadoc)
     * @see java.lang.Comparable#compareTo(java.lang.Object)
     */
    @Override
    public final int compareTo(final D o) {
        return name().compareTo(o.name());
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Definition#name()
     */
    @Override
    public final String name() {
        return localKey();
    }
}
