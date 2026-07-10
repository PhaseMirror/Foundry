// Types derived from Hologram schemas

export interface HologramBase {
  $schema?: string;
  namespace: string;
  parent?: string;
  conformance: boolean;
  version?: string;
  description?: string;
}

export interface ConformanceRequirement {
  required: boolean;
  description: string;
  schema: string;
}

export interface HologramComponent extends HologramBase {
  component: {
    version: string;
    description: string;
    conformance_requirements: {
      interface: ConformanceRequirement;
      docs: ConformanceRequirement;
      test: ConformanceRequirement;
      manager: ConformanceRequirement;
      [key: string]: ConformanceRequirement;
    };
    validation_rules?: Array<{
      id: string;
      description: string;
    }>;
    artifacts?: Array<{
      file: string;
      type: 'spec' | 'conformance';
      cid: string;
    }>;
  };
}

export interface ComponentFiles {
  spec: any;
  interface: any;
  docs: any;
  test: any;
  manager: any;
  dependency?: any;
  build?: any;
  log?: any;
  view?: any;
  [key: string]: any;
}

export interface ComponentIndex {
  namespace: string;
  artifacts: {
    spec?: string;
    interface?: string;
    docs?: string;
    test?: string;
    manager?: string;
    dependency?: string;
    build?: string;
    log?: string;
    view?: string;
    [key: string]: string | undefined;
  };
}

export interface ValidationResult {
  success: boolean;
  namespace?: string;
  errors?: ValidationError[];
  warnings?: string[];
}

export interface ValidationError {
  file: string;
  message: string;
  path?: string;
}

export interface ReadResult {
  success: boolean;
  namespace: string;
  files?: Partial<ComponentFiles>;
  error?: string;
}

export interface UpdateResult {
  success: boolean;
  namespace: string;
  updatedFiles?: string[];
  errors?: ValidationError[];
}

export interface DeleteResult {
  success: boolean;
  namespace: string;
  message?: string;
  error?: string;
}

// File type mappings
export const FILE_TYPES: Record<string, 'spec' | 'conformance'> = {
  'spec': 'spec',
  'interface': 'conformance',
  'docs': 'conformance',
  'test': 'conformance',
  'manager': 'conformance',
  'dependency': 'conformance',
  'build': 'conformance',
  'log': 'conformance',
  'view': 'conformance',
};

// Required conformance files (read from hologram.component.json)
export interface RequiredConformance {
  interface: boolean;
  docs: boolean;
  test: boolean;
  manager: boolean;
  [key: string]: boolean;
}