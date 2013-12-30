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

import com.blockwithme.meta.types.Named;
import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.Property;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.modules.typedgraph.TypeValue;

/**
 * A process. It could be a Java Virtual Machine.
 *
 * It could run any number of applications. Any access to it goes over an
 * application.
 *
 * @author monster
 */
@TypeValue("Process")
public interface Process extends Named {
    /** Returns the process type. */
    @Property("processType")
    ProcessType getProcessType();

    /** Sets the process type. */
    @Property("processType")
    void setProcessType(final ProcessType processType);

    /** The applications *currently* running in this process. */
    @Adjacency(label = "hosts")
    Application[] getApplications();

    /** Adds an application *currently* running in this process. */
    @Adjacency(label = "hosts")
    void addApplication(final Application app);

    /** Removes an application *currently* running in this process. */
    @Adjacency(label = "hosts")
    void removeApplication(final Application app);

    /** Returns the application with the given name, if any. */
    @GremlinGroovy("it.out('hosts').has('name',name)")
    Application findApplication(@GremlinParam("name") final String name);
}
