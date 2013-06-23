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

import com.blockwithme.meta.types.Service;
import com.blockwithme.meta.types.ServiceType;
import com.blockwithme.meta.types.Type;
import com.blockwithme.properties.impl.ImplGraph;

/**
 * @author monster
 *
 */
public class ServiceImpl extends BundledDefinition<Service> implements Service {

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected ServiceImpl(final ImplGraph<Long> graph, final String localKey,
            final Long when) {
        super(graph, localKey, when);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Service#lifecycle()
     */
    @Override
    public ServiceType lifecycle() {
        return get("lifecycle", ServiceType.class);
    }

    /** Sets the lifecycle */
    public ServiceImpl lifecycle(final ServiceType value) {
        set(bundle(), "lifecycle", value);
        return this;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.Service#api()
     */
    @Override
    public Type api() {
        return get("api", Type.class);
    }

    /** Sets the api */
    public ServiceImpl api(final Type value) {
        set(bundle(), "api", value);
        return this;
    }
}
