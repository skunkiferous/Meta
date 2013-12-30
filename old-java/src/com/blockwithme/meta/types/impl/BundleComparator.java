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

import java.util.Comparator;
import java.util.Objects;

import com.blockwithme.meta.Statics;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.meta.types.Feature;

/**
 * A bundle comparator compares bundles based on their distance to the root
 * bundle of the application. The smallest/lowest bundle is the root bundle.
 *
 * @author monster
 */
public class BundleComparator implements Comparator<Bundle> {
    /** The application. */
    private final Feature appFeature;

    /** Creates a BundleComparator */
    public BundleComparator(final Feature appFeature) {
        this.appFeature = Objects.requireNonNull(appFeature);
    }

    /* (non-Javadoc)
     * @see java.util.Comparator#compare(java.lang.Object, java.lang.Object)
     */
    @Override
    public int compare(final Bundle bundle1, final Bundle bundle2) {
        final int depth1 = Statics.distanceFromRoot(appFeature, bundle1);
        final int depth2 = Statics.distanceFromRoot(appFeature, bundle2);
        int result = (depth1 - depth2);
        if (result == 0) {
            final String name1 = bundle1.getName();
            final String name2 = bundle2.getName();
            result = name1.compareTo(name2);
        }
        return result;
    }
}
