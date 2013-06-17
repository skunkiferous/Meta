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

import com.blockwithme.meta.Configurable;
import com.blockwithme.meta.Definition;
import com.blockwithme.meta.impl.BaseDefinition;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Bundled;

/**
 * @author monster
 *
 */
public abstract class BundledDefinition<C extends Definition<C> & Bundled>
        extends BaseDefinition<C> implements Bundled {

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected BundledDefinition(final Configurable parent,
            final String localKey, final Long when) {
        super(parent, localKey, when);
    }

    /** The bundle. */
    @Override
    public Bundle bundle() {
        return ancestor(Bundle.class);
    }
}
