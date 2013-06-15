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

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.ArrayUtils;

import com.blockwithme.meta.types.Access;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Container;
import com.blockwithme.meta.types.Kind;
import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.Type;

/**
 * @author monster
 */
public class TypeImpl extends BundledDefinition<Type> implements Type {
    /**
     * @param theApp
     * @param theName
     */
    protected TypeImpl(final Bundle theBundle, final String theName) {
        super(theBundle, theName);
    }

    /** Returns the "unique key" to this definition. */
    @Override
    public String key() {
        return bundle().key() + "|Type|" + name();
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#type()
     */
    @Override
    public Class<?> type() {
        return (Class<?>) getProperty(null, "type");
    }

    /** Sets the type. */
    public TypeImpl type(final Class<?> value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE, "type", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isData()
     */
    @Override
    public boolean isData() {
        return (Boolean) getProperty(null, "isData");
    }

    /** Sets the type. */
    public TypeImpl isData(final boolean value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE, "isData", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isArray()
     */
    @Override
    public boolean isArray() {
        return (Boolean) getProperty(null, "isArray");
    }

    /** Sets the type. */
    public TypeImpl isArray(final boolean value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE, "isArray",
                value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isRoot()
     */
    @Override
    public boolean isRoot() {
        return (Boolean) getProperty(null, "isRoot");
    }

    /** Sets the type. */
    public TypeImpl isRoot(final boolean value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE, "isRoot", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isTrait()
     */
    @Override
    public boolean isTrait() {
        return (Boolean) getProperty(null, "isTrait");
    }

    /** Sets the type. */
    public TypeImpl isTrait(final boolean value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE, "isTrait",
                value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isImplementation()
     */
    @Override
    public boolean isImplementation() {
        return (Boolean) getProperty(null, "isImplementation");
    }

    /** Sets the type. */
    public TypeImpl isImplementation(final boolean value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE,
                "isImplementation", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isFinal()
     */
    @Override
    public boolean isFinal() {
        return (Boolean) getProperty(null, "isFinal");
    }

    /** Sets the type. */
    public TypeImpl isFinal(final boolean value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE, "isFinal",
                value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#kind()
     */
    @Override
    public Kind kind() {
        return (Kind) getProperty(null, "kind");
    }

    /** Sets the type. */
    public TypeImpl kind(final Kind value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE, "kind", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#access()
     */
    @Override
    public Access access() {
        return (Access) getProperty(null, "access");
    }

    /** Sets the type. */
    public TypeImpl access(final Access value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE, "access", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#biggerThanParents()
     */
    @Override
    public boolean biggerThanParents(final Long time) {
        return (Boolean) getProperty(time, "biggerThanParents");
    }

    /** Sets the type. */
    public TypeImpl biggerThanParents(final Bundle bundle, final long time,
            final boolean value) {
        return (TypeImpl) setProperty(bundle, time, "biggerThanParents", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#allProperties()
     */
    @Override
    public Property[] allProperties(final Long time) {
        return (Property[]) getProperty(time, "allProperties");
    }

    /** Sets the type. */
    public TypeImpl allProperties(final Bundle bundle, final long time,
            final Property[] value) {
        return (TypeImpl) setProperty(bundle, time, "allProperties", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#directProperties()
     */
    @Override
    public Property[] directProperties(final Long time) {
        return (Property[]) getProperty(time, "directProperties");
    }

    /** Sets the directProperties. */
    public TypeImpl directProperties(final Bundle bundle, final long time,
            final Property[] value) {
        return (TypeImpl) setProperty(bundle, time, "directProperties", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findProperty(java.lang.String)
     */
    @Override
    public Property findProperty(final Long time, final String name) {
        return findDefinition(time, "allProperties", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findDirectProperty(java.lang.String)
     */
    @Override
    public Property findDirectProperty(final Long time, final String name) {
        return findDefinition(time, "directProperties", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#parents()
     */
    @Override
    public Type[] parents(final Long time) {
        return (Type[]) getProperty(time, "parents");
    }

    /** Sets the type. */
    public TypeImpl parents(final Bundle bundle, final long time,
            final Type[] value) {
        return (TypeImpl) setProperty(bundle, time, "parents", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findParent(java.lang.String)
     */
    @Override
    public Type findParent(final Long time, final String name) {
        return findDefinition(time, "parents", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#directParents()
     */
    @Override
    public Type[] directParents(final Long time) {
        return (Type[]) getProperty(time, "directParents");
    }

    /** Sets the type. */
    public TypeImpl directParents(final Bundle bundle, final long time,
            final Type[] value) {
        return (TypeImpl) setProperty(bundle, time, "directParents", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findDirectParent(java.lang.String)
     */
    @Override
    public Type findDirectParent(final Long time, final String name) {
        return findDefinition(time, "directParents", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isParent(com.blockwithme.meta.types.Type)
     */
    @Override
    public boolean isParent(final Long time, final Type otherType) {
        return ArrayUtils.contains(parents(time), otherType);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isDirectParent(com.blockwithme.meta.types.Type)
     */
    @Override
    public boolean isDirectParent(final Long time, final Type otherType) {
        return ArrayUtils.contains(directParents(time), otherType);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#children()
     */
    @Override
    public Type[] children(final Long time) {
        return (Type[]) getProperty(time, "children");
    }

    /** Sets the type. */
    public TypeImpl children(final Bundle bundle, final long time,
            final Type[] value) {
        return (TypeImpl) setProperty(bundle, time, "children", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findChild(java.lang.String)
     */
    @Override
    public Type findChild(final Long time, final String name) {
        return findDefinition(time, "children", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#directChildren()
     */
    @Override
    public Type[] directChildren(final Long time) {
        return (Type[]) getProperty(time, "directChildren");
    }

    /** Sets the type. */
    public TypeImpl directChildren(final Bundle bundle, final long time,
            final Type[] value) {
        return (TypeImpl) setProperty(bundle, time, "directChildren", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findDirectChild(java.lang.String)
     */
    @Override
    public Type findDirectChild(final Long time, final String name) {
        return findDefinition(time, "directChildren", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isChild(com.blockwithme.meta.types.Type)
     */
    @Override
    public boolean isChild(final Long time, final Type otherType) {
        return ArrayUtils.contains(children(time), otherType);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isDirectChild(com.blockwithme.meta.types.Type)
     */
    @Override
    public boolean isDirectChild(final Long time, final Type otherType) {
        return ArrayUtils.contains(directChildren(time), otherType);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#containers()
     */
    @Override
    public Container[] containers(final Long time) {
        return (Container[]) getProperty(time, "containers");
    }

    /** Sets the type. */
    public TypeImpl containers(final Bundle bundle, final long time,
            final Container[] value) {
        return (TypeImpl) setProperty(bundle, time, "containers", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findContainer(com.blockwithme.meta.types.Type)
     */
    @Override
    public Container[] findContainer(final Long time, final Type otherType) {
        List<Container> result = null;
        for (final Container c : containers(time)) {
            if (c.container() == otherType) {
                if (result == null) {
                    result = new ArrayList<>();
                }
                result.add(c);
            }
        }
        return (result == null) ? new Container[0] : result
                .toArray(new Container[result.size()]);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#domain()
     */
    @Override
    public Type domain() {
        return (Type) getProperty(null, "domain");
    }

    /** Sets the type. */
    public TypeImpl domain(final Type value) {
        return (TypeImpl) setProperty(bundle(), Long.MIN_VALUE, "domain", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#persistence()
     */
    @Override
    public String[] persistence(final Long time) {
        return (String[]) getProperty(time, "persistence");
    }

    /** Sets the type. */
    public TypeImpl persistence(final Bundle bundle, final long time,
            final String[] value) {
        return (TypeImpl) setProperty(bundle, time, "persistence", value);
    }

    /** Called, after the initial values have been set. */
    @Override
    protected void _postInit() {
        checkProp("type", Class.class);
        checkProp("isData", Boolean.class);
        checkProp("isArray", Boolean.class);
        checkProp("isRoot", Boolean.class);
        checkProp("isTrait", Boolean.class);
        checkProp("isImplementation", Boolean.class);
        checkProp("isFinal", Boolean.class);
        checkProp("kind", Kind.class);
        checkProp("access", Access.class);
        checkProp("biggerThanParents", Boolean.class);
        checkProp("allProperties", Property[].class);
        checkProp("directProperties", Property[].class);
        checkProp("parents", Type[].class);
        checkProp("directParents", Type[].class);
        checkProp("children", Type[].class);
        checkProp("directChildren", Type[].class);
        checkProp("containers", Container[].class);
        checkProp("domain", Type.class);
        checkProp("persistence", String[].class);
        super._postInit();
        postInit(allProperties(null));
        postInit(parents(null));
        postInit(children(null));
        postInit(containers(null));
        postInit(domain());
    }
}
