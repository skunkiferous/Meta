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
package com.blockwithme.meta.annotations.impl;

import java.util.TreeMap;

import com.blockwithme.meta.Statics;
import com.blockwithme.meta.annotations.PropMap;

/**
 * A sorted map implementation that helps converting data on demand.
 *
 * @author monster
 */
public class PropMapImpl extends TreeMap<String, Object> implements PropMap {

    /**  */
    private static final long serialVersionUID = 1L;

    /** Default constructor. */
    public PropMapImpl() {
        // NOP
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.PropMap#get(java.lang.String, java.lang.Class)
     */
    @Override
    public <E> E get(final String property, final Class<E> type) {
        return Statics.convert(get(property), type);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.annotations.PropMap#remove(java.lang.String, java.lang.Class)
     */
    @Override
    public <E> E remove(final String property, final Class<E> type) {
        return Statics.convert(remove(property), type);
    }
}
