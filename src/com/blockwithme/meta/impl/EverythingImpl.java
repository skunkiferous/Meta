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
package com.blockwithme.meta.impl;

import com.blockwithme.meta.Everything;
import com.blockwithme.meta.infrastructure.HostingProvider;
import com.blockwithme.meta.infrastructure.Process;
import com.blockwithme.meta.meta.Concept;
import com.blockwithme.meta.types.Application;
import com.blockwithme.properties.impl.RootImpl;

/**
 * @author monster
 *
 */
public class EverythingImpl extends RootImpl<Long> implements Everything {

    /**
     * @param now
     */
    public EverythingImpl(final Long now) {
        super(now);
        // TODO Auto-generated constructor stub
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Configurable#app()
     */
    @Override
    public Application app() {
        // TODO Auto-generated method stub
        return null;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Everything#currentProcess()
     */
    @Override
    public Process currentProcess() {
        // TODO Auto-generated method stub
        return null;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Everything#providers()
     */
    @Override
    public HostingProvider[] providers() {
        // TODO Auto-generated method stub
        return null;
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.Everything#concepts()
     */
    @Override
    public Concept[] concepts() {
        // TODO Auto-generated method stub
        return null;
    }
}
