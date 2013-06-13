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
package com.blockwithme.meta.infrastructure.impl;

import com.blockwithme.meta.Dynamic;
import com.blockwithme.meta.impl.BaseConfigurable;
import com.blockwithme.meta.infrastructure.ActorRef;
import com.blockwithme.meta.infrastructure.AppState;
import com.blockwithme.meta.infrastructure.Application;
import com.blockwithme.meta.infrastructure.Connection;
import com.blockwithme.meta.infrastructure.Connector;

/**
 * @author monster
 *
 * TODO Add setters
 */
public class AppStateImpl extends BaseConfigurable<AppState> implements
        AppState {

    /**
     * @param theApp
     */
    protected AppStateImpl(final Application theApp) {
        super(theApp);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.AppState#connectors()
     */
    @Override
    public Connector[] connectors() {
        return (Connector[]) getProperty(null, "connectors");
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.AppState#findConnector(java.lang.String)
     */
    @Override
    public Connector findConnector(final String name) {
        return findDefinition(null, "connectors", name);
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.AppState#connections()
     */
    @Override
    @Dynamic
    public Connection[] connections() {
        return (Connection[]) getProperty(null, "connections");
    }

    /* (non-Javadoc)
     * @see com.blockwithme.meta.infrastructure.AppState#actors()
     */
    @Override
    @Dynamic
    public ActorRef[] actors() {
        return (ActorRef[]) getProperty(null, "actors");
    }
}
