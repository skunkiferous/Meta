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
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Bundled;

/**
 * @author monster
 *
 */
public abstract class BundledConfigurable<C extends Bundled<C>> extends
        BaseConfigurable<C> implements Bundled<C> {
    /**  */
    private final Bundle bundle;

    /** The bundle. */
    @Override
    public Bundle bundle() {
        return bundle;
    }

    /**
     * @param theApp
     * @param theName
     */
    protected BundledConfigurable(final Bundle theBundle) {
        super(theBundle.app());
        // theBundle cannot be null here, because it would have failed when getting app
        bundle = theBundle;
    }
}
