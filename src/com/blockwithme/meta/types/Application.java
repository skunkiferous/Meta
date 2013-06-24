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

import com.blockwithme.meta.infrastructure.Connection;
import com.blockwithme.meta.infrastructure.Connector;
import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.Property;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.typed.TypeValue;

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
@TypeValue("Application")
public interface Application extends Bundled, Named {
    /** Returns all the currently available bundles within this application. */
    // TODO Use Gremlin to find all dependencies
//    Bundle[] bundles();

    /**
     * Returns the bundles with the given name, if any.
     */
    // TODO
//    Bundle findBundle(final String name);

    /**
     * Returns the shortest distance from the root bundle (0) through
     * dependencies. Returns Integer.MAX_VALUE when unknown/not found.
     */
    // TODO
    @GremlinGroovy(value = "0", frame = false)
    int distanceFromRoot(final Bundle bundle);

    /** Returns a Bundle Comparator. */
    @Property("bundleComparator")
    Comparator<Bundle> getBundleComparator();

    /** Returns a Bundle Comparator. */
    @Property("bundleComparator")
    void setBundleComparator(final Comparator<Bundle> bundleComparator);

    /** Is this a distributed application? */
    @Property("distributed")
    boolean isDistributed();

    /** Is this a distributed application? */
    @Property("distributed")
    void setDistributed(final boolean distributed);

    /** Is this a JVM-based application? */
    @Property("javaApp")
    boolean isJavaApp();

    /** Is this a JVM-based application? */
    @Property("javaApp")
    void setJavaApp(final boolean javaApp);

    /** Returns all the application connectors. */
    @Adjacency(label = "listensTo")
    Connector[] getConnectors();

    /** Adds an application connector. */
    @Adjacency(label = "listensTo")
    void addConnector(final Connector connector);

    /** Removes an application connector. */
    @Adjacency(label = "listensTo")
    void removeConnector(final Connector connector);

    /** Returns the connector with the given name, if any. */
    @GremlinGroovy("it.out('listensTo').has('name',name)")
    Connector findConnector(@GremlinParam("name") final String name);

    /**
     * Returns all the application connections to other applications.
     * Connections with "clients" are not included here.
     */
    @Adjacency(label = "talksTo")
    Connection[] getConnections();

    /** Adds an application connection. */
    @Adjacency(label = "talksTo")
    void addConnection(final Connection connection);

    /** Removes an application connection. */
    @Adjacency(label = "talksTo")
    void removeConnection(final Connection connection);

    /** Returns the connection with the given name, if any. */
    @GremlinGroovy("it.out('talksTo').has('name',name)")
    Connection findConnection(@GremlinParam("name") final String name);

    /**
     * Returns the actors belonging to a particular application.
     *
     * TODO: Not sure if that is the right thing to do; there could be very many ...
     */
//    @Adjacency(label = "listensTo")
//    ActorRef[] actors();
}
