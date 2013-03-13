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

import java.net.URL;

import com.blockwithme.meta.Definition;
import com.blockwithme.meta.types.ActorRef;
import com.blockwithme.meta.types.Bundle;

/**
 * An application is a specific *application configuration* of an application,
 * running on a specific execution environment. It is defined by its bundles,
 * and other resources, as well as it's execution environment.
 *
 * Application instances with the same name, refer to the same logical
 * application.
 *
 * @author monster
 */
public interface Application extends Definition<Application> {
    /** Return the bundles. */
    Bundle[] bundles();

    /** Is this a distributed application? */
    boolean distributed();

    /** Is this a JVM-based application? */
    boolean javaApp();

    /** Returns the name of all the application connectors. */
    String[] connectors();

    /** Returns the URL to the connector with the given name, if any. */
    URL findConnector(final String name);

    /** Returns the actors belonging to a particular application. */
    ActorRef[] actors();
}
