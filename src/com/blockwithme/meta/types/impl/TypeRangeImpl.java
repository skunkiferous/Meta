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

import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.Type;
import com.blockwithme.meta.types.TypeFilter;
import com.blockwithme.meta.types.TypeRange;

/**
 * @author monster
 *
 */
public class TypeRangeImpl extends BundledConfigurable implements TypeRange {

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected TypeRangeImpl(final Property parent, final String localKey,
            final Long when) {
        super(parent, localKey, when);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.TypeRange#actualInstance()
     */
    @Override
    public boolean actualInstance() {
        return get("actualInstance", Boolean.class);
    }

    /** Sets the ID */
    public TypeRangeImpl actualInstance(final Bundle bundle, final long time,
            final boolean value) {
        set(bundle, "actualInstance", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.TypeRange#contains()
     */
    @Override
    public boolean contains() {
        return get("contains", Boolean.class);
    }

    /** Sets the ID */
    public TypeRangeImpl contains(final Bundle bundle, final long time,
            final boolean value) {
        set(bundle, "contains", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.TypeRange#children()
     */
    @Override
    public Type[] children() {
        return listChildValues("children", Type.class, false);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.TypeRange#findChild(java.lang.String)
     */
    @Override
    public Type findChild(final String name) {
        return findDefinition("children", name, Type.class);
    }

    /** Sets the ID */
    public TypeRangeImpl children(final Bundle bundle, final long time,
            final Type[] value) {
        set(bundle, "children", value, time, false);
        return this;
    }

    /**
     * Defines the implicitly accepted children types, of the declared type,
     * through custom filters.
     * An empty list does not imply an exact type match.
     */
    @SuppressWarnings("unchecked")
    public Class<? extends TypeFilter>[] childrenFilters() {
        return listChildValues("childrenFilters", Class.class, false);
    }

    /** Sets the ID */
    public TypeRangeImpl childrenFilters(final Bundle bundle, final long time,
            final Class<? extends TypeFilter>[] value) {
        set(bundle, "childrenFilters", value, time, false);
        return this;
    }

    /**
     * Additional type restrictions, which limit the types of the instances,
     * by specifying that some other type cannot be accepted.
     */
    public Class<?>[] excludes() {
        return listChildValues("excludes", Class.class, false);
    }

    /** Sets the ID */
    public TypeRangeImpl excludes(final Bundle bundle, final long time,
            final Class<?>[] value) {
        set(bundle, "excludes", value, time, false);
        return this;
    }

    /** Implicit type exclusion, through custom filters. */
    @SuppressWarnings("unchecked")
    public Class<? extends TypeFilter>[] excludeFilters(final Long time) {
        return listChildValues("excludeFilters", Class.class, false);
    }

    /** Sets the ID */
    public TypeRangeImpl excludeFilters(final Bundle bundle, final long time,
            final Class<? extends TypeFilter>[] value) {
        set(bundle, "excludeFilters", value, time, false);
        return this;
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
