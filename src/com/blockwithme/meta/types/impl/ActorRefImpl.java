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

import com.blockwithme.meta.types.ActorRef;
import com.blockwithme.meta.types.Bundle;
import com.blockwithme.properties.impl.ImplGraph;
import com.blockwithme.properties.impl.PropertiesImpl;

/**
 * @author monster
 *
 */
public class ActorRefImpl extends PropertiesImpl<Long> implements ActorRef {

    /**
     * @param parent
     * @param localKey
     * @param when
     */
    protected ActorRefImpl(final ImplGraph<Long> graph, final String localKey,
            final Long when) {
        super(graph, localKey, when);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.types.ActorRef#id()
     */
    @Override
    public long id() {
        return find("id", Long.class);
    }

    /** Sets the ID */
    public ActorRefImpl id(final Bundle bundle, final long theID) {
        set(bundle, "id", theID);
        return this;
    }
}
