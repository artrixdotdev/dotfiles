import chalk from "chalk";
import ora from "ora";

// Create a spinner
let spinner: ReturnType<typeof ora> | null = null;

/**
 * Log a regular message
 */
export function log(message: string): void {
   console.log(message);
}

/**
 * Log an info message
 */
export function info(message: string): void {
   console.info(chalk.blue(`i ${message}`));
}

/**
 * Log a success message
 */
export function success(message: string): void {
   console.log(chalk.green(`✓ ${message}`));
}

/**
 * Log a warning message
 */
export function warn(message: string): void {
   console.warn(chalk.yellow(`! ${message}`));
}

/**
 * Log an error message
 */
export function error(message: string): void {
   console.error(chalk.red(`✗ ${message}`));
}

/**
 * Start a spinner with message
 */
export function startSpinner(message: string): void {
   if (spinner) {
      spinner.stop();
   }
   spinner = ora(message).start();
}

/**
 * Stop spinner with success
 */
export function succeedSpinner(message: string): void {
   if (spinner) {
      spinner.succeed(message);
      spinner = null;
   }
}

/**
 * Stop spinner with failure
 */
export function failSpinner(message: string): void {
   if (spinner) {
      spinner.fail(message);
      spinner = null;
   }
}

/**
 * Update spinner text
 */
export function updateSpinner(message: string): void {
   if (spinner) {
      spinner.text = message;
   }
}
