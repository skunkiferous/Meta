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
import com.blockwithme.meta.types.Container;
import com.blockwithme.meta.types.Property;
import com.blockwithme.meta.types.Type;

/**
 * @author monster
 *
 */
public class ContainerImpl extends BundledConfigurable implements Container {

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected ContainerImpl(final Type parent, final String localKey,
            final Long when) {
        super(parent, localKey, when);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Container#container()
     */
    @Override
    public Type container() {
        return get("container", Type.class);
    }

    /** Sets the container */
    public ContainerImpl container(final Bundle bundle, final Type theContainer) {
        set(bundle, "container", theContainer);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Container#property()
     */
    @Override
    public Property property() {
        return get("property", Property.class);
    }

    /** Sets the property */
    public ContainerImpl property(final Bundle bundle, final Type theProperty) {
        set(bundle, "property", theProperty);
        return this;
    }

    /** Called, after the initial values have been set. */
    @Override
    protected void _postInit() {
        checkProp("container", Type.class);
        checkProp("property", Property.class);
        super._postInit();
        postInit(container(), property());
    }
}
