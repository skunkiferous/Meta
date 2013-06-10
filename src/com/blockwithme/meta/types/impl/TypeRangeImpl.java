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

import com.blockwithme.meta.impl.BaseConfigurable;
import com.blockwithme.meta.types.Type;
import com.blockwithme.meta.types.TypeFilter;
import com.blockwithme.meta.types.TypeRange;

/**
 * @author monster
 *
 */
public class TypeRangeImpl extends BaseConfigurable<TypeRange> implements
        TypeRange {
    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.TypeRange#actualInstance()
     */
    @Override
    public boolean actualInstance() {
        return (Boolean) getProperty("actualInstance");
    }

    /** Sets the ID */
    public TypeRangeImpl actualInstance(final boolean value) {
        return (TypeRangeImpl) setProperty("actualInstance", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.TypeRange#contains()
     */
    @Override
    public boolean contains() {
        return (Boolean) getProperty("contains");
    }

    /** Sets the ID */
    public TypeRangeImpl contains(final boolean value) {
        return (TypeRangeImpl) setProperty("contains", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.TypeRange#children()
     */
    @Override
    public Type[] children() {
        return (Type[]) getProperty("children");
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.TypeRange#findChild(java.lang.String)
     */
    @Override
    public Type findChild(final String name) {
        return findDefinition("children", name);
    }

    /** Sets the ID */
    public TypeRangeImpl children(final Type[] value) {
        return (TypeRangeImpl) setProperty("children", value);
    }

    /**
     * Defines the implicitly accepted children types, of the declared type,
     * through custom filters.
     * An empty list does not imply an exact type match.
     */
    @SuppressWarnings("unchecked")
    public Class<? extends TypeFilter>[] childrenFilters() {
        return (Class<? extends TypeFilter>[]) getProperty("childrenFilters");
    }

    /** Sets the ID */
    public TypeRangeImpl childrenFilters(
            final Class<? extends TypeFilter>[] value) {
        return (TypeRangeImpl) setProperty("childrenFilters", value);
    }

    /**
     * Additional type restrictions, which limit the types of the instances,
     * by specifying that some other type cannot be accepted.
     */
    public Class<?>[] excludes() {
        return (Class<?>[]) getProperty("excludes");
    }

    /** Sets the ID */
    public TypeRangeImpl excludes(final Class<?>[] value) {
        return (TypeRangeImpl) setProperty("excludes", value);
    }

    /** Implicit type exclusion, through custom filters. */
    @SuppressWarnings("unchecked")
    public Class<? extends TypeFilter>[] excludeFilters() {
        return (Class<? extends TypeFilter>[]) getProperty("excludeFilters");
    }

    /** Sets the ID */
    public TypeRangeImpl excludeFilters(
            final Class<? extends TypeFilter>[] value) {
        return (TypeRangeImpl) setProperty("excludeFilters", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.TypeRange#accept(com.blockwithme.meta.types.Type)
     */
    @Override
    public boolean accept(final Type type) {
        // TODO Auto-generated method stub
        throw new UnsupportedOperationException("TODO");
    }

    /** Called, after the initial values have been set. */
    @Override
    protected void _postInit() {
        checkProp("actualInstance", Boolean.class);
        checkProp("contains", Boolean.class);
        checkProp("children", Type[].class);
        checkProp("childrenFilters", Class[].class);
        checkProp("excludes", Class[].class);
        checkProp("excludeFilters", Class[].class);
        super._postInit();
    }
}
