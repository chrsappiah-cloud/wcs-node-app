import type { Config } from 'jest';

const config: Config = {
  roots: ['<rootDir>/apps', '<rootDir>/packages'],
  testMatch: ['**/*.spec.ts'],
  testEnvironment: 'node',
  transform: {
    '^.+\\.(t|j)s$': 'ts-jest'
  },
  moduleNameMapper: {
    '^@dreamflow/types$': '<rootDir>/packages/types/src',
    '^@dreamflow/schemas$': '<rootDir>/packages/schemas/src',
    '^@dreamflow/api-client$': '<rootDir>/packages/api-client/src',
    '^@dreamflow/ui$': '<rootDir>/packages/ui/src'
  }
};

export default config;
