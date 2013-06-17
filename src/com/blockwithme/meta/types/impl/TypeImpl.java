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
     * @param parent
     * @param localKey
     * @param when
     */
    protected TypeImpl(final Bundle parent, final String localKey,
            final Long when) {
        super(parent, localKey, when);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#type()
     */
    @Override
    public Class<?> type() {
        return get("type", Class.class);
    }

    /** Sets the type. */
    public TypeImpl type(final Class<?> value) {
        set(bundle(), "type", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isData()
     */
    @Override
    public boolean isData() {
        return get("isData", Boolean.class);
    }

    /** Sets the type. */
    public TypeImpl isData(final boolean value) {
        set(bundle(), "isData", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isArray()
     */
    @Override
    public boolean isArray() {
        return get("isArray", Boolean.class);
    }

    /** Sets the type. */
    public TypeImpl isArray(final boolean value) {
        set(bundle(), "isArray", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isRoot()
     */
    @Override
    public boolean isRoot() {
        return get("isRoot", Boolean.class);
    }

    /** Sets the type. */
    public TypeImpl isRoot(final boolean value) {
        set(bundle(), "isRoot", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isTrait()
     */
    @Override
    public boolean isTrait() {
        return get("isTrait", Boolean.class);
    }

    /** Sets the type. */
    public TypeImpl isTrait(final boolean value) {
        set(bundle(), "isTrait", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isImplementation()
     */
    @Override
    public boolean isImplementation() {
        return get("isImplementation", Boolean.class);
    }

    /** Sets the type. */
    public TypeImpl isImplementation(final boolean value) {
        set(bundle(), "isImplementation", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isFinal()
     */
    @Override
    public boolean isFinal() {
        return get("isFinal", Boolean.class);
    }

    /** Sets the type. */
    public TypeImpl isFinal(final boolean value) {
        set(bundle(), "isFinal", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#kind()
     */
    @Override
    public Kind kind() {
        return get("kind", Kind.class);
    }

    /** Sets the type. */
    public TypeImpl kind(final Kind value) {
        set(bundle(), "kind", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#access()
     */
    @Override
    public Access access() {
        return get("access", Access.class);
    }

    /** Sets the type. */
    public TypeImpl access(final Access value) {
        set(bundle(), "access", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#biggerThanParents()
     */
    @Override
    public boolean biggerThanParents() {
        return get("biggerThanParents", Boolean.class);
    }

    /** Sets the type. */
    public TypeImpl biggerThanParents(final Bundle bundle, final long time,
            final boolean value) {
        set(bundle, "biggerThanParents", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#allProperties()
     */
    @Override
    public Property[] allProperties() {
        return listChildValues("allProperties", Property.class, false);
    }

    /** Sets the type. */
    public TypeImpl allProperties(final Bundle bundle, final long time,
            final Property[] value) {
        set(bundle, "allProperties", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#directProperties()
     */
    @Override
    public Property[] directProperties() {
        return listChildValues("directProperties", Property.class, false);
    }

    /** Sets the directProperties. */
    public TypeImpl directProperties(final Bundle bundle, final long time,
            final Property[] value) {
        set(bundle, "directProperties", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findProperty(java.lang.String)
     */
    @Override
    public Property findProperty(final String name) {
        return findDefinition("allProperties", name, Property.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findDirectProperty(java.lang.String)
     */
    @Override
    public Property findDirectProperty(final String name) {
        return findDefinition("directProperties", name, Property.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#parents()
     */
    @Override
    public Type[] parents() {
        return listChildValues("parents", Type.class, false);
    }

    /** Sets the type. */
    public TypeImpl parents(final Bundle bundle, final long time,
            final Type[] value) {
        set(bundle, "parents", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findParent(java.lang.String)
     */
    @Override
    public Type findParent(final String name) {
        return findDefinition("parents", name, Type.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#directParents()
     */
    @Override
    public Type[] directParents() {
        return listChildValues("directParents", Type.class, false);
    }

    /** Sets the type. */
    public TypeImpl directParents(final Bundle bundle, final long time,
            final Type[] value) {
        set(bundle, "directParents", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findDirectParent(java.lang.String)
     */
    @Override
    public Type findDirectParent(final String name) {
        return findDefinition("directParents", name, Type.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isParent(com.blockwithme.meta.types.Type)
     */
    @Override
    public boolean isParent(final Type otherType) {
        return ArrayUtils.contains(parents(), otherType);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isDirectParent(com.blockwithme.meta.types.Type)
     */
    @Override
    public boolean isDirectParent(final Type otherType) {
        return ArrayUtils.contains(directParents(), otherType);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#children()
     */
    @Override
    public Type[] children() {
        return listChildValues("children", Type.class, false);
    }

    /** Sets the type. */
    public TypeImpl children(final Bundle bundle, final long time,
            final Type[] value) {
        set(bundle, "children", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findChild(java.lang.String)
     */
    @Override
    public Type findChild(final String name) {
        return findDefinition("children", name, Type.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#directChildren()
     */
    @Override
    public Type[] directChildren() {
        return listChildValues("directChildren", Type.class, false);
    }

    /** Sets the type. */
    public TypeImpl directChildren(final Bundle bundle, final long time,
            final Type[] value) {
        set(bundle, "directChildren", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findDirectChild(java.lang.String)
     */
    @Override
    public Type findDirectChild(final String name) {
        return findDefinition("directChildren", name, Type.class);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isChild(com.blockwithme.meta.types.Type)
     */
    @Override
    public boolean isChild(final Type otherType) {
        return ArrayUtils.contains(children(), otherType);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isDirectChild(com.blockwithme.meta.types.Type)
     */
    @Override
    public boolean isDirectChild(final Type otherType) {
        return ArrayUtils.contains(directChildren(), otherType);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#containers()
     */
    @Override
    public Container[] containers() {
        return listChildValues("containers", Container.class, false);
    }

    /** Sets the type. */
    public TypeImpl containers(final Bundle bundle, final long time,
            final Container[] value) {
        set(bundle, "containers", value, time, false);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findContainer(com.blockwithme.meta.types.Type)
     */
    @Override
    public Container[] findContainer(final Type otherType) {
        List<Container> result = null;
        for (final Container c : containers()) {
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
        return get("domain", Type.class);
    }

    /** Sets the type. */
    public TypeImpl domain(final Type value) {
        set(bundle(), "domain", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#persistence()
     */
    @Override
    public String[] persistence() {
        return get("persistence", String[].class);
    }

    /** Sets the type. */
    public TypeImpl persistence(final Bundle bundle, final long time,
            final String[] value) {
        set(bundle, "persistence", value, time, false);
        return this;
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
        postInit(allProperties());
        postInit(parents());
        postInit(children());
        postInit(containers());
        postInit(domain());
    }
}
