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
package com.blockwithme.meta.types;

import java.util.Comparator;

import com.blockwithme.meta.Dynamic;
import com.blockwithme.meta.infrastructure.Connection;
import com.blockwithme.meta.infrastructure.Connector;
import com.blockwithme.properties.Properties;

/**
 * An application is a specific *application configuration* of an application,
 * running on a specific execution environment. It is defined by its bundles,
 * and other resources, as well as it's execution environment.
 *
 * Application instances with the same name, refer to the same logical
 * application.
 *
 * We assume Connectors are unchangeable, once created...
 *
 * @author monster
 */
public interface Application extends Properties<Long>, Bundled {
    /** The application name. */
    String name();

    /** The "root" application bundle, which can use any number of other bundles. */
    @Override
    Bundle bundle();

    /** Returns all the currently available bundles within this application. */
    @Dynamic
    Bundle[] bundles();

    /**
     * Returns the bundles with the given name, if any.
     */
    Bundle findBundle(final String name);

    /**
     * Returns the shortest distance from the root bundle (0) through
     * dependencies. Returns Integer.MAX_VALUE when unknown/not found.
     */
    int distanceFromRoot(final Bundle bundle);

    /** Returns a Bundle Comparator. */
    Comparator<Bundle> bundleComparator();

    /** Is this a distributed application? */
    boolean distributed();

    /** Is this a JVM-based application? */
    boolean javaApp();

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
