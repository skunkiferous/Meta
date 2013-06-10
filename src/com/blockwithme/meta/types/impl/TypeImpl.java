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
import com.blockwithme.meta.types.Container;
import com.blockwithme.meta.types.Kind;
import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.Type;

/**
 * @author monster
 */
public class TypeImpl extends BundleChild<Type> implements Type {
    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#type()
     */
    @Override
    public Class<?> type() {
        return (Class<?>) getProperty("type");
    }

    /** Sets the type. */
    public TypeImpl type(final Class<?> value) {
        return (TypeImpl) setProperty("type", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isData()
     */
    @Override
    public boolean isData() {
        return (Boolean) getProperty("isData");
    }

    /** Sets the type. */
    public TypeImpl isData(final boolean value) {
        return (TypeImpl) setProperty("isData", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isArray()
     */
    @Override
    public boolean isArray() {
        return (Boolean) getProperty("isArray");
    }

    /** Sets the type. */
    public TypeImpl isArray(final boolean value) {
        return (TypeImpl) setProperty("isArray", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isRoot()
     */
    @Override
    public boolean isRoot() {
        return (Boolean) getProperty("isRoot");
    }

    /** Sets the type. */
    public TypeImpl isRoot(final boolean value) {
        return (TypeImpl) setProperty("isRoot", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isTrait()
     */
    @Override
    public boolean isTrait() {
        return (Boolean) getProperty("isTrait");
    }

    /** Sets the type. */
    public TypeImpl isTrait(final boolean value) {
        return (TypeImpl) setProperty("isTrait", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isImplementation()
     */
    @Override
    public boolean isImplementation() {
        return (Boolean) getProperty("isImplementation");
    }

    /** Sets the type. */
    public TypeImpl isImplementation(final boolean value) {
        return (TypeImpl) setProperty("isImplementation", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#isFinal()
     */
    @Override
    public boolean isFinal() {
        return (Boolean) getProperty("isFinal");
    }

    /** Sets the type. */
    public TypeImpl isFinal(final boolean value) {
        return (TypeImpl) setProperty("isFinal", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#kind()
     */
    @Override
    public Kind kind() {
        return (Kind) getProperty("kind");
    }

    /** Sets the type. */
    public TypeImpl kind(final Kind value) {
        return (TypeImpl) setProperty("kind", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#access()
     */
    @Override
    public Access access() {
        return (Access) getProperty("access");
    }

    /** Sets the type. */
    public TypeImpl access(final Access value) {
        return (TypeImpl) setProperty("access", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#biggerThanParents()
     */
    @Override
    public boolean biggerThanParents() {
        return (Boolean) getProperty("biggerThanParents");
    }

    /** Sets the type. */
    public TypeImpl biggerThanParents(final boolean value) {
        return (TypeImpl) setProperty("biggerThanParents", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#allProperties()
     */
    @Override
    public Property[] allProperties() {
        return (Property[]) getProperty("allProperties");
    }

    /** Sets the type. */
    public TypeImpl allProperties(final Property[] value) {
        return (TypeImpl) setProperty("allProperties", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#directProperties()
     */
    @Override
    public Property[] directProperties() {
        return (Property[]) getProperty("directProperties");
    }

    /** Sets the directProperties. */
    public TypeImpl directProperties(final Property[] value) {
        return (TypeImpl) setProperty("directProperties", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findProperty(java.lang.String)
     */
    @Override
    public Property findProperty(final String name) {
        return findDefinition("allProperties", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findDirectProperty(java.lang.String)
     */
    @Override
    public Property findDirectProperty(final String name) {
        return findDefinition("directProperties", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#parents()
     */
    @Override
    public Type[] parents() {
        return (Type[]) getProperty("parents");
    }

    /** Sets the type. */
    public TypeImpl parents(final Type[] value) {
        return (TypeImpl) setProperty("parents", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findParent(java.lang.String)
     */
    @Override
    public Type findParent(final String name) {
        return findDefinition("parents", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#directParents()
     */
    @Override
    public Type[] directParents() {
        return (Type[]) getProperty("directParents");
    }

    /** Sets the type. */
    public TypeImpl directParents(final Type[] value) {
        return (TypeImpl) setProperty("directParents", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findDirectParent(java.lang.String)
     */
    @Override
    public Type findDirectParent(final String name) {
        return findDefinition("directParents", name);
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
        return (Type[]) getProperty("children");
    }

    /** Sets the type. */
    public TypeImpl children(final Type[] value) {
        return (TypeImpl) setProperty("children", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findChild(java.lang.String)
     */
    @Override
    public Type findChild(final String name) {
        return findDefinition("children", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#directChildren()
     */
    @Override
    public Type[] directChildren() {
        return (Type[]) getProperty("directChildren");
    }

    /** Sets the type. */
    public TypeImpl directChildren(final Type[] value) {
        return (TypeImpl) setProperty("directChildren", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#findDirectChild(java.lang.String)
     */
    @Override
    public Type findDirectChild(final String name) {
        return findDefinition("directChildren", name);
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
        return (Container[]) getProperty("containers");
    }

    /** Sets the type. */
    public TypeImpl containers(final Container[] value) {
        return (TypeImpl) setProperty("containers", value);
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
        return (Type) getProperty("domain");
    }

    /** Sets the type. */
    public TypeImpl domain(final Type value) {
        return (TypeImpl) setProperty("domain", value);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Type#persistence()
     */
    @Override
    public String[] persistence() {
        return (String[]) getProperty("persistence");
    }

    /** Sets the type. */
    public TypeImpl persistence(final String[] value) {
        return (TypeImpl) setProperty("persistence", value);
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
