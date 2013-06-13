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
package com.blockwithme.meta.infrastructure;

import com.blockwithme.meta.Configurable;
import com.blockwithme.meta.Dynamic;

/**
 * AppState represents the dynamic state of an application.
 *
 * @author monster
 */
public interface AppState extends Configurable<AppState> {

    /** Returns all the application connectors. */
    Connector[] connectors();

    /** Returns the connector with the given name, if any. */
    Connector findConnector(final String name);

    /**
     * Returns all the application connections to other applications.
     * Connections with "clients" are not included here.
     */
    @Dynamic
    Connection[] connections();

    /**
     * Returns the actors belonging to a particular application.
     *
     * TODO: Not sure if that is the right thing to do; there could be very many ...
     */
    @Dynamic
    ActorRef[] actors();

}
